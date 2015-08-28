/**
 *
 * Based upon the Red Pitaya monitor program written by Crt Valentincic <crt.valentincic@redpitaya.com>
 *
 * The monitor program has been modified to introduce PID functionality.
 *
 * @Author: Lewis Woolfson <lw58@st-andrews.ac.uk>
 * @Date 28/08/2015
 *
 * The PID controller is controlled via a command line user interface.
 * This program takes in the relevant PID parameters and stores them in memory.
 * The original functionality of the monitor program is retained
 *
 * This part of code is written in C programming language.
 * Please visit http://en.wikipedia.org/wiki/C_(programming_language)
 * for more details on the language used herein.
 */

#define _GNU_SOURCE

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <signal.h>
#include <fcntl.h>
#include <ctype.h>
//#include <termios.h>
#include <sys/types.h>
#include <sys/mman.h>
#include <stdint.h>
#include <string.h>

#include "version.h"

#define FATAL do { fprintf(stderr, "Error at line %d, file %s (%d) [%s]\n", \
  __LINE__, __FILE__, errno, strerror(errno)); exit(1); } while(0)
 
#define MAP_SIZE 4096UL
#define MAP_MASK (MAP_SIZE - 1)

#define DEBUG_MONITOR 0

int parse_from_argv_par(int a_argc, char **a_argv, double** a_values, ssize_t* a_len);
int parse_from_argv(int a_argc, char **a_argv, unsigned long* a_addr, int* a_type, unsigned long** a_values, ssize_t* a_len);
int parse_from_stdin(unsigned long* a_addr, int* a_type, unsigned long** a_values, ssize_t* a_len);
uint32_t read_value(uint32_t a_addr);
void write_values(unsigned long a_addr, int a_type, unsigned long* a_values, ssize_t a_len);

void* map_base = (void*)(-1);

const uint32_t c_addrAms=0x40400000;

typedef enum {
	eAmsTemp=0,
	eAmsAI0,
	eAmsAI1,
	eAmsAI2,
	eAmsAI3,
	eAmsAI4,
	eAmsVCCPINT,
	eAmsVCCPAUX,
	eAmsVCCBRAM,
	eAmsVCCINT,
	eAmsVCCAUX,
	eAmsVCCDDR,
	eAmsAO0,
	eAmsAO1,
	eAmsAO2,
	eAmsAO3,
	eSendNum
} ams_t;

const uint8_t amsDesc[eSendNum][20]={
	"Temp(0C-85C)",
	"AI0(0-3.5V)",
	"AI1(0-3.5V)",
	"AI2(0-3.5V)",
	"AI3(0-3.5V)",
	"AI4(5V0)",
	"VCCPINT(1V0)",
	"VCCPAUX(1V8)",
	"VCCBRAM(1V0)",
	"VCCINT(1V0)",
	"VCCAUX(1V8)",
	"VCCDDR(1V5)",
	"AO0(0-1.8V)",
	"AO1(0-1.8V)",
	"AO2(0-1.8V)",
	"AO3(0-1.8V)",
};

#define ADC_FULL_RANGE_CNT 0xfff
#define ADC_POS_RANGE_CNT  0x7ff

#define SLOW_DAC_NUM 4
#define SLOW_DAC_RANGE_CNT 0x9c

typedef struct {
	uint32_t aif[5];
	uint32_t reserved[3];
	uint32_t dac[SLOW_DAC_NUM];
	uint32_t temp;
	uint32_t vccPint;
	uint32_t vccPaux;
	uint32_t vccBram;
	uint32_t vccInt;
	uint32_t vccAux;
	uint32_t vccDddr;
} amsReg_t;


static const int NUM_PIDS = 8;

// default PID resolution values
static const int PSR_FAST_DEFAULT = 12;
static const int ISR_FAST_DEFAULT = 18;
static const int DSR_FAST_DEFAULT = 10;

static const int PSR_SLOW_DEFAULT = 8;
static const int ISR_SLOW_DEFAULT = 20;
static const int DSR_SLOW_DEFAULT = 6;

static const int ICD_DEFAULT = 125000000;
static const int ICD_DEFAULT_SLOW = 100000;
static const int TOL_DEFAULT = 0;

typedef struct {
	int setpoint;
	int kp;
	int ki;
	int kd;
	int irst;
} PID ;

typedef struct {
	char *setpoint_addr;
	char *kp_addr;
	char *ki_addr;
	char *kd_addr;
	char *irst_addr;
	char *PSR;
	char *ISR;
	char *DSR;
	char *ICD;
	char *tol;
} PIDaddr;

char *getHex(int value, int pidNum);
void write_pid_values(int argc, char **argv, int fd);
void initPIDs(PIDaddr *pid);
void inputVal(int *ptr, int pidNum);
uint32_t read_pid_value(uint32_t a_addr);

static float AmsConversion(ams_t a_ch, unsigned int a_raw)
{
	float uAdc;
	float val=0;
	switch(a_ch){
		case eAmsAI0:
		case eAmsAI1:
		case eAmsAI2:
		case eAmsAI3:{
			if(a_raw>0x7ff){
				a_raw=0;
			}
			uAdc=(float)a_raw/0x7ff*0.5;
			val=uAdc*(30.0+4.99)/4.99;
		}
		break;
		case eAmsAI4:{
			uAdc=(float)a_raw/ADC_FULL_RANGE_CNT*1.0;
			val=uAdc*(56.0+4.99)/4.99;
		}
		break;
		case eAmsTemp:{
			val=((float)a_raw*503.975) / ADC_FULL_RANGE_CNT - 273.15;
		}
		break;
		case eAmsVCCPINT:
		case eAmsVCCPAUX:
		case eAmsVCCBRAM:
		case eAmsVCCINT:
		case eAmsVCCAUX:
		case eAmsVCCDDR:{
			val=((float)a_raw/ADC_FULL_RANGE_CNT)*3.0;
		}
		break;
		case eAmsAO0:
		case eAmsAO1:
		case eAmsAO2:
		case eAmsAO3:
			val=((float)(a_raw>>16)/SLOW_DAC_RANGE_CNT)*1.8;
		break;
		case eSendNum:
			break;
	}
	return val;
}

static void AmsList(amsReg_t * a_amsReg)
{
	uint32_t i,raw;
	float val;
	printf("#ID\tDesc\t\tRaw\tVal\n");
	for(i=0;i<eSendNum;i++){
		switch(i){
			case eAmsTemp:
			    raw=a_amsReg->temp;
			break;
			case eAmsAI0:
				raw=a_amsReg->aif[0];
			break;
			case eAmsAI1:
				raw=a_amsReg->aif[1];
			break;
			case eAmsAI2:
				raw=a_amsReg->aif[2];
			break;
			case eAmsAI3:
				raw=a_amsReg->aif[3];
				break;
			case eAmsAI4:
				raw=a_amsReg->aif[4];
				break;
			case eAmsVCCPINT:
				raw=a_amsReg->vccPint;
				break;
			case eAmsVCCPAUX:
				raw=a_amsReg->vccPaux;
				break;
			case eAmsVCCBRAM:
				raw=a_amsReg->vccBram;
				break;
			case eAmsVCCINT:
				raw=a_amsReg->vccInt;
				break;
			case eAmsVCCAUX:
				raw=a_amsReg->vccAux;
				break;
			case eAmsVCCDDR:
				raw=a_amsReg->vccDddr;
				break;
			case eAmsAO0:
				raw=a_amsReg->dac[0];
				break;
			case eAmsAO1:
				raw=a_amsReg->dac[1];
				break;
			case eAmsAO2:
				raw=a_amsReg->dac[2];
				break;
			case eAmsAO3:
				raw=a_amsReg->dac[3];
				break;
			case eSendNum:
				break;
		}
		val=AmsConversion(i, raw);
		printf("%d\t%s\t%x\t%.3f\n",i,&amsDesc[i][0],raw,val);
	}
}

static void DacRead(amsReg_t * a_amsReg)
{
	uint32_t i;
	uint32_t raw;
	float val=0;
	for(i=0;i<SLOW_DAC_NUM;i++){
		raw=a_amsReg->dac[i];
		val=AmsConversion(eAmsAO0+i, raw);
		printf("%f\n",val);
	}
}

static void DacWrite(amsReg_t * a_amsReg, double * a_val, ssize_t a_cnt)
{
	uint32_t i;
	for(i=0;i<a_cnt;i++){
		uint32_t dacCnt;
		if(a_val[i]<0){
		   a_val[i]=0;
		}
		if(a_val[i]>1.8){
		   a_val[i]=1.8;
		}
		dacCnt=(a_val[i]/1.8)*SLOW_DAC_RANGE_CNT;
		//dacCnt&=0x9c;
		dacCnt*=256*256; // dacCnt=dacCnt<<16;
		a_amsReg->dac[i]=dacCnt;
	}
}

int main(int argc, char **argv) {


	int fd = -1;
	int retval = EXIT_SUCCESS;

	if(argc < 2) {

		fprintf(stderr,
                        "%s version %s-%s\n"
			"\nUsage:\n"
			"\tcontrol pid: pid\n"
			"\tread addr: address\n"
                        "\twrite addr: address value\n"
			"\tread analog mixed signals: -ams\n"
			"\tset slow DAC: -sdac AO0 AO1 AO2 AO3 [V]\n",
                        argv[0], VERSION_STR, REVISION_STR);
		return EXIT_FAILURE;
	}

	if((fd = open("/dev/mem", O_RDWR | O_SYNC)) == -1) FATAL;

	/* Read from standard input */
	if (strncmp(argv[1], "-ams", 4) == 0) {
		uint32_t addr = c_addrAms;
		amsReg_t* ams=NULL;
		// Map one page
		map_base = mmap(0, MAP_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, fd, addr & ~MAP_MASK);
		if(map_base == (void *) -1) FATAL;

		ams = map_base + (addr & MAP_MASK);
		AmsList(ams);

		if (map_base != (void*)(-1)) {
			if(munmap(map_base, MAP_SIZE) == -1) FATAL;
			map_base = (void*)(-1);
		}
	}
	else if (strncmp(argv[1], "-sdac", 5) == 0) {
		uint32_t addr = c_addrAms;
		amsReg_t* ams=NULL;

		double *val = NULL;
		ssize_t val_count = 0;
		parse_from_argv_par(argc, argv, &val, &val_count);

		if(val_count>SLOW_DAC_NUM){
			val_count=SLOW_DAC_NUM;
		}

		// Map one page
		map_base = mmap(0, MAP_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, fd, addr & ~MAP_MASK);
		if(map_base == (void *) -1) FATAL;

		ams = map_base + (addr & MAP_MASK);

		if (val_count == 0) {
			DacRead(ams);
		}
		else{
			DacWrite(ams, val, val_count);
		}

		if (map_base != (void*)(-1)) {
			if(munmap(map_base, MAP_SIZE) == -1) FATAL;
			map_base = (void*)(-1);
		}

	}
	else if (strncmp(argv[1], "-", 1) == 0) {
		//printf("IM HERE");
		unsigned long addr;
		unsigned long *val = NULL;
		int access_type = 'w';
		ssize_t val_count = 0;
		while ( parse_from_stdin(&addr, &access_type, &val, &val_count) != -1) {
			if (addr == 0) {
				continue;
			}
			/* Map one page */
			map_base = mmap(0, MAP_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, fd, addr & ~MAP_MASK);
			if(map_base == (void *) -1) FATAL;

			if (val_count == 0) {
				read_value(addr);
			}
			else {
				write_values(addr, access_type, val, val_count);
			}
			if (map_base != (void*)(-1)) {
				if(munmap(map_base, MAP_SIZE) == -1) FATAL;
				map_base = (void*)(-1);
			}
#if DEBUG_MONITOR
			printf("addr/type: %lu/%c\n", addr, access_type);

			printf("val (%ld):", val_count);
			for (ssize_t i = 0; i < val_count; ++i) {
				printf("%lu ", val[i]);
			}
			if (val != NULL) {
				free(val);
				val = NULL;
			}
			printf("\n");
#endif
		}
		goto exit;
	}

	// PID Controller
	else if(strncmp(argv[1], "pid", 3) == 0) {

		printf(
		            "version 1.0\n\n"
					"PID Controller Menu:\n\n"
					"\t1: Fast Analog 11\n"
					"\t2: Fast Analog 12\n"
					"\t3: Fast Analog 21\n"
					"\t4: Fast Analog 22\n"
					"\t5: Slow Analog 0\n"
					"\t6: Slow Analog 1\n"
					"\t7: Slow Analog 2\n"
					"\t8: Slow Analog 3\n"
					"\t9: Advanced Parameters\n\n"
		       );


		int pidNum;
		PID pid;
		PIDaddr *addr = (PIDaddr *)malloc(sizeof(PIDaddr)*NUM_PIDS);
		initPIDs(addr);

		strcpy(argv[0], "/tmp/monitor");

		printf("Enter menu number (1-9): ");
		scanf("%d", &pidNum);

	    while (pidNum < 1 || pidNum > 9) {
	    	printf("Error: PID number out of range, try again: ");
	    	scanf("%d", &pidNum);
	    }

	    if(pidNum == 9) {

			printf(
						"\n\n------ Advanced Parameters ------\n\n"
						"PID Controllers: \n"
						"\t1: Fast Analog 11\n"
						"\t2: Fast Analog 12\n"
						"\t3: Fast Analog 21\n"
						"\t4: Fast Analog 22\n"
						"\t5: Slow Analog 0\n"
						"\t6: Slow Analog 1\n"
						"\t7: Slow Analog 2\n"
						"\t8: Slow Analog 3\n\n"
			       );

	    	int pidNum2;

			printf("Choose a PID Controller (1-8): ");
			scanf("%d", &pidNum2);

		    while (pidNum2 < 1 || pidNum2 > 8) {
		    	printf("Error: PID number out of range, try again: ");
		    	scanf("%d", &pidNum2);
		    }

		    printf("\n------ Current Advanced Parameters for PID %d ------\n\n", pidNum2);
			strcpy(argv[1], addr[pidNum2-1].PSR);
			printf("Proportional Resolution: ");
			write_pid_values(argc, argv, fd);

			strcpy(argv[1], addr[pidNum2-1].ISR);
			printf("Integral Resolution: ");
			write_pid_values(argc, argv, fd);

			strcpy(argv[1], addr[pidNum2-1].DSR);
			printf("Derivative Resolution: ");
			write_pid_values(argc, argv, fd);

			strcpy(argv[1], addr[pidNum2-1].ICD);
			printf("Integral Frequency (Hz): ");
			write_pid_values(argc, argv, fd);

			strcpy(argv[1], addr[pidNum2-1].tol);
			printf("Absolute Error Tolerance: ");
			write_pid_values(argc, argv, fd);

			char response;
			printf("\nDo you want to update the advanced parameters for PID %d (Y/N)? ", pidNum2);
			scanf(" %c", &response);
			while(toupper(response) != 'Y' && toupper(response) != 'N') {
				printf("Error, please enter either Y or N: ");
				scanf(" %c", &response);
			}

			if(toupper(response) == 'Y') {

				printf("\n------ New Advanced Parameters for PID %d ------\n\n", pidNum2);
				printf(
							"Advanced Parameters:\n"
							"\t1: Proportional Resolution\n"
							"\t2: Integral  Resolution\n"
							"\t3: Derivative Resolution\n"
							"\t4: Integrator Frequency\n"
							"\t5: Error Tolerance\n\n"
					   );

				int featNum;

				printf("Choose an advanced parameter (1-5): ");
				scanf("%d", &featNum);

				while (featNum < 1 || featNum > 5) {
					printf("Error: Feature number out of range (1-5), try again: ");
					scanf("%d", &featNum);
				}

				argv[2] = (char*) malloc(11);
				argc = 3; // set the number of input arguments for new parameters

				// set the P digital input output pins for reading in the voltages - perhaps not required
				strcpy(argv[1],  "0x40000010");
				strcpy(argv[2], "0xff");
				write_pid_values(argc, argv, fd);


				char *hex;
				int PSR, ISR, DSR, tol;
				long ICD;

				switch (featNum) {

				case 1:

					if (pidNum2 <= 4) {
						// Fast PIDs
						printf("Set proportional resolution within range 5-15 (default %d): ", PSR_FAST_DEFAULT );
					} else {
						// Slow PIDs
						printf("Set proportional resolution within range 5-15 (default %d): ", PSR_SLOW_DEFAULT );
					}

					scanf("%d", &PSR);
					while (PSR < 5 || PSR > 15) {
							printf("Error: Proportional resolution out of range (5-15), try again: ");
							scanf("%d", &PSR);
					}


					// set PSR value to register
					hex = getHex(PSR, pidNum2);
					strcpy(argv[1],  addr[pidNum2-1].PSR);
					strcpy(argv[2], hex);
					write_pid_values(argc, argv, fd);
					break;

				case 2:

					if (pidNum2 <= 4) {
						// Fast PIDs
						printf("Set integral resolution within range 14-24 (default %d): ", ISR_FAST_DEFAULT );
					} else {
						// Slow PIDs
						printf("Set integral resolution within range 14-24 (default %d): ", ISR_SLOW_DEFAULT );
					}

					// Fast and slow PIDs
					scanf("%d", &ISR);
					while (ISR < 14 || ISR > 24) {
						printf("Error: Integral resolution out of range (14-24), try again: ");
						scanf("%d", &ISR);
					}

					// set ISR value to register
					hex = getHex(ISR, pidNum2);
					strcpy(argv[1],  addr[pidNum2-1].ISR);
					strcpy(argv[2], hex);
					write_pid_values(argc, argv, fd);
					break;

				case 3:

					if (pidNum2 <= 4) {
						// Fast PIDs
						printf("Set derivative resolution within range 3-13 (default %d): ", DSR_FAST_DEFAULT );
					} else {
						// Slow PIDs
						printf("Set derivative resolution within range 3-13 (default %d): ", DSR_SLOW_DEFAULT );
					}

					scanf("%d", &DSR);
					while (DSR < 3 || DSR > 13) {
					   printf("Error: Derivative resolution out of range (3-13), try again: ");
					   scanf("%d", &DSR);
					}

					// set PSR value to register
					hex = getHex(DSR, pidNum2);
					strcpy(argv[1],  addr[pidNum2-1].DSR);
					strcpy(argv[2], hex);
					write_pid_values(argc, argv, fd);

					break;
				case 4:


					if (pidNum2 <= 4) {
						// Fast PIDs
						printf("Set integrator frequency within range 1Hz-125MHz (default %d): ", ICD_DEFAULT );
						scanf("%li", &ICD);

						while (ICD < 1 || ICD > 125000000) {
						   printf("Error: Integrator frequency out of range (1-125000000), try again: ");
						   scanf("%li", &ICD);
						}
						ICD = (125000000 / ICD) - 1 ; // subtracting 1 so that it becomes a true divider (we want ICD = 0 when desired speed is 125 MHz)

					} else {
						// Slow PIDs
						printf("Set integrator frequency within range 1Hz-100kHz (default %d): ", ICD_DEFAULT_SLOW );
						scanf("%li", &ICD);

						while (ICD < 1 || ICD > 100000) {
						   printf("Error: Integrator frequency out of range (1-100000), try again: ");
						   scanf("%li", &ICD);
						}
						ICD = (100000 / ICD) - 1 ; // subtracting 1 so that it becomes a true divider (we want ICD = 0 when desired speed is 125 MHz)
					}


					// actual ICD value is 125MHz / desired_clock_speed

					// set PSR value to register
					hex = getHex(ICD, pidNum2);
					strcpy(argv[1],  addr[pidNum2-1].ICD);
					strcpy(argv[2], hex);
					write_pid_values(argc, argv, fd);

					break;
				case 5:

					printf("Set absolute error tolerance within range 0-511 (default %d): ", TOL_DEFAULT );
					scanf("%d", &tol);

					while (tol < 0 || tol > 511) {
					   printf("Error: tolerance out of range (0-511), try again: ");
					   scanf("%d", &tol);
					}

					// set tolerance value to register
					hex = getHex(tol, pidNum2);
					strcpy(argv[1],  addr[pidNum2-1].tol);
					strcpy(argv[2], hex);
					write_pid_values(argc, argv, fd);

					break;
				}

				free(hex);
				free(addr);
				free(argv[2]);
			}

	    } else {

			argc = 2;

			strcpy(argv[1], addr[pidNum-1].setpoint_addr);
			printf("\n------ Current Parameters for PID %d ------\n\n", pidNum);
			printf("Set point: ");
			write_pid_values(argc, argv, fd);

			strcpy(argv[1], addr[pidNum-1].kp_addr);
			printf("Proportional Gain (Kp): ");
			write_pid_values(argc, argv, fd);

			strcpy(argv[1], addr[pidNum-1].ki_addr);
			printf("Integral Gain (Ki): ");
			write_pid_values(argc, argv, fd);

			strcpy(argv[1], addr[pidNum-1].kd_addr);
			printf("Derivative Gain (Kd): ");
			write_pid_values(argc, argv, fd);

			strcpy(argv[1], addr[pidNum-1].irst_addr);
			printf("Integral Reset (1 on, 0 off):  ");
			write_pid_values(argc, argv, fd);



			// create new input argument
			argv[2] = (char*) malloc(11);
			argc = 3; // set the number of input arguments for new parameters

			// set the P digital input output pins for reading in the voltages
			strcpy(argv[1],  "0x40000010");
			strcpy(argv[2], "0xff");
			write_pid_values(argc, argv, fd);

			char response;
			printf("\nDo you want to update the parameters for PID %d (Y/N)? ", pidNum);
			scanf(" %c", &response);
			while(toupper(response) != 'Y' && toupper(response) != 'N') {
				printf("Error, please enter either Y or N: ");
				scanf(" %c", &response);
			}

			if(toupper(response) == 'Y') {

				printf("\n------ New Parameters for PID %d ------\n\n", pidNum);
				// New parameters
				int *ptr = &pid.setpoint;

				printf("Enter Set Point: ");
				scanf("%d", &pid.setpoint);
				inputVal(ptr, pidNum);
				//TODO change so the PID setpoint is from 0 to 4096

//				if(pidNum > 4) {
//					// for slow PIDs
//					while (pid.setpoint < 0 || pid.setpoint > 4095) {
//						printf("Error: Out of range (0 to 4095), try again: ");
//						scanf("%d", &pid.setpoint);
//					}
//				}

				ptr = &pid.kp;
				printf("Enter Proportional Gain Kp: ");
				scanf("%d", &pid.kp);
				inputVal(ptr, pidNum);

				ptr = &pid.ki;
				printf("Enter Integral Gain Ki: ");
				scanf("%d", &pid.ki);
				inputVal(ptr, pidNum);

				ptr = &pid.kd;
				printf("Enter Derivative Gain Kd: ");
				scanf("%d", &pid.kd);
				inputVal(ptr, pidNum);

				printf("Integrator Reset 1 (on) or 0 (off)? ");
				scanf("%d", &pid.irst);

				while (pid.irst != 1 && pid.irst != 0) {
						printf("Error: input must be 1 or 0, try again: ");
						scanf("%d", &pid.irst);
				}

				//pid.irst = !pid.irst; // integrator reset of 0 is high and 1 is low, that's what i thought but apparently not the case

				// for the integrator reset it reads in the values 1111 so to turn on the integrator reset we need to set a value to a 1

				char *hex = getHex(pid.setpoint, pidNum);
				strcpy(argv[1], addr[pidNum-1].setpoint_addr);
				strcpy(argv[2], hex);
				write_pid_values(argc, argv, fd);

				hex = (char *) getHex(pid.kp, pidNum);
				strcpy(argv[1], addr[pidNum-1].kp_addr);
				strcpy(argv[2], hex);
				write_pid_values(argc, argv, fd);

				hex = (char *) getHex(pid.ki, pidNum);
				strcpy(argv[1], addr[pidNum-1].ki_addr);
				strcpy(argv[2], hex);
				write_pid_values(argc, argv, fd);

				hex = (char *) getHex(pid.kd, pidNum);
				strcpy(argv[1], addr[pidNum-1].kd_addr);
				strcpy(argv[2], hex);
				write_pid_values(argc, argv, fd);

				hex = (char *) getHex(pid.irst, pidNum); // pid.irst is never negative so doesn't undergo transformation in getHex()
				strcpy(argv[1], addr[pidNum-1].irst_addr);
				strcpy(argv[2], hex); //should just be a 1 or a 0
				write_pid_values(argc, argv, fd);

				free(addr);
				free(argv[2]);
				free(hex);
			}
	    }
	}
	/* Read from command line */
	else {

		unsigned long addr;
		unsigned long *val = NULL;
		int access_type = 'w';
		ssize_t val_count = 0;
		parse_from_argv(argc, argv, &addr, &access_type, &val, &val_count);

		/* Map one page */
		map_base = mmap(0, MAP_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, fd, addr & ~MAP_MASK);
		if(map_base == (void *) -1) FATAL;
			
		if (addr != 0) {
			if (val_count == 0) {
				read_value(addr);
			}
			else {
				write_values(addr, access_type, val, val_count);
			}
		}
		if (map_base != (void*)(-1)) {
			if(munmap(map_base, MAP_SIZE) == -1) FATAL;
			map_base = (void*)(-1);
		}
#if DEBUG_MONITOR
		printf("addr/type: %lu/%c\n", addr, access_type);

		printf("val (%ld):", val_count);
		for (ssize_t i = 0; i < val_count; ++i) {
			printf("%lu ", val[i]);
		}
		
		if (val != NULL) {
			free(val);
			val = NULL;
		}
		printf("\n");
#endif
	}

	// edited? may not work
exit:

	if (map_base != (void*)(-1)) {
		if(munmap(map_base, MAP_SIZE) == -1) FATAL;
	}
	if (fd != -1) {
		close(fd);
	}

	return retval;

}

void inputVal(int *ptr, int pidNum) {

	if (pidNum >= 1 && pidNum <= 4) {
		// for 14-bit fast pid
		while(*ptr < -8192 || *ptr > 8191) {
			printf("Error: Out of range (-8192 to 8191), try again: ");
			scanf("%d", ptr);
			fflush(stdout);
		}
	} else {
		// 12 bit slow pids - do i need to go from 0 to 4096, wait till forum post.
		// TODO but its not actually the full range, the DAC cuts off, no?
		while(*ptr < 0 || *ptr > 4095) {
			printf("Error: Out of range (0 to 4095), try again: ");
			scanf("%d", ptr);
			fflush(stdout);
		}
	}

}

void initPIDs(PIDaddr *pid) {

	/*
	 * See 'PID Controller.docx' for more information
	 * index key:
	 * 0 => Fast 11
	 * 1 => Fast 12
	 * 2 => Fast 21
	 * 3 => Fast 22
	 * 4 => Slow 1
	 * 5 => Slow 2
	 * 6 => Slow 3
	 * 7 => Slow 4
	 */

	pid[0].setpoint_addr = "0x40600010";
	pid[0].kp_addr = "0x40600014";
	pid[0].ki_addr = "0x40600018";
	pid[0].kd_addr = "0x4060001C";
	pid[0].irst_addr = "0x40600090";
	pid[0].PSR = "0x406000B0";
	pid[0].ISR = "0x406000B4";
	pid[0].DSR = "0x406000B8";
	pid[0].ICD = "0x406000BC";
	pid[0].tol = "0x40600130";

	pid[1].setpoint_addr = "0x40600020";
	pid[1].kp_addr = "0x40600024";
	pid[1].ki_addr = "0x40600028";
	pid[1].kd_addr = "0x4060002C";
	pid[1].irst_addr = "0x40600094";
	pid[1].PSR = "0x406000C0";
	pid[1].ISR = "0x406000C4";
	pid[1].DSR = "0x406000C8";
	pid[1].ICD = "0x406000CC";
	pid[1].tol = "0x40600134";

	pid[2].setpoint_addr = "0x40600030";
	pid[2].kp_addr = "0x40600034";
	pid[2].ki_addr = "0x40600038";
	pid[2].kd_addr = "0x4060003C";
	pid[2].irst_addr = "0x40600098";
	pid[2].PSR = "0x406000D0";
	pid[2].ISR = "0x406000D4";
	pid[2].DSR = "0x406000D8";
	pid[2].ICD = "0x406000DC";
	pid[2].tol = "0x40600138";

	pid[3].setpoint_addr = "0x40600040";
	pid[3].kp_addr = "0x40600044";
	pid[3].ki_addr = "0x40600048";
	pid[3].kd_addr = "0x4060004C";
	pid[3].irst_addr = "0x4060009C";
	pid[3].PSR = "0x406000E0";
	pid[3].ISR = "0x406000E4";
	pid[3].DSR = "0x406000E8";
	pid[3].ICD = "0x406000EC";
	pid[3].tol = "0x4060013C";

	pid[4].setpoint_addr = "0x40600050";
	pid[4].kp_addr = "0x40600054";
	pid[4].ki_addr = "0x40600058";
	pid[4].kd_addr = "0x4060005C";
	pid[4].irst_addr = "0x406000A0";
	pid[4].PSR = "0x406000F0";
	pid[4].ISR = "0x406000F4";
	pid[4].DSR = "0x406000F8";
	pid[4].ICD = "0x406000FC";
	pid[4].tol = "0x40600140";

	pid[5].setpoint_addr = "0x40600060";
	pid[5].kp_addr = "0x40600064";
	pid[5].ki_addr = "0x40600068";
	pid[5].kd_addr = "0x4060006C";
	pid[5].irst_addr = "0x406000A4";
	pid[5].PSR = "0x40600100";
	pid[5].ISR = "0x40600104";
	pid[5].DSR = "0x40600108";
	pid[5].ICD = "0x4060010C";
	pid[5].tol = "0x40600144";

	pid[6].setpoint_addr = "0x40600070";
	pid[6].kp_addr = "0x40600074";
	pid[6].ki_addr = "0x40600078";
	pid[6].kd_addr = "0x4060007C";
	pid[6].irst_addr = "0x406000A8";
	pid[6].PSR = "0x40600110";
	pid[6].ISR = "0x40600114";
	pid[6].DSR = "0x40600118";
	pid[6].ICD = "0x4060011C";
	pid[6].tol = "0x40600148";

	pid[7].setpoint_addr = "0x40600080";
	pid[7].kp_addr = "0x40600084";
	pid[7].ki_addr = "0x40600088";
	pid[7].kd_addr = "0x4060008C";
	pid[7].irst_addr = "0x406000AC";
	pid[7].PSR = "0x40600120";
	pid[7].ISR = "0x40600124";
	pid[7].DSR = "0x40600128";
	pid[7].ICD = "0x4060012C";
	pid[7].tol = "0x4060014C";
}


char *getHex(int value, int pidNum) {
	// TODO ADJUST FOR THE FAST AND THE SLOW DACS, SLOW DACS WILL HAVE A DIFFERENT RANGE (12-bit rather than 14-bit, not 16384)

	// convert the user number (-8192 to 8191) into a hexadecimal number
	// negative values are first converted to the range -1 => 16383, -8192 => 8192
	// negative values are 16384 + (neg. value)
	// NOTE that this works for the 14-bit fast dac that has this larger range

	char *out = malloc(15); // 4 character hex number
	char *prefix = "0x";

	if (pidNum >= 1 && pidNum <= 4) {
		if (value < 0) value = 16384 + value;	//adjust for the negative values (14 bit)
	} else {
		// need to check if this is the correct transformation
		if (value < 0) value = 4096 + value;
	}

	snprintf(out, 15, "%x", value);	 // get hexadecimal from decimal

	char *buff = malloc(strlen(out)+1);

	strcat(buff, prefix);
	strcat(buff, out);

	return buff;
}


void write_pid_values(int argc, char **argv, int fd) {
	unsigned long addr;
	unsigned long *val = NULL;
	int access_type = 'w';
	ssize_t val_count = 0;
	parse_from_argv(argc, argv, &addr, &access_type, &val, &val_count);

	/* Map one page */
	map_base = mmap(0, MAP_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, fd, addr & ~MAP_MASK);
	if(map_base == (void *) -1) FATAL;

	if (addr != 0) {
		if (val_count == 0) {
			read_pid_value(addr);
		}
		else {
			write_values(addr, access_type, val, val_count);
		}
	}
	if (map_base != (void*)(-1)) {
		if(munmap(map_base, MAP_SIZE) == -1) FATAL;
		map_base = (void*)(-1);
	}
#if DEBUG_MONITOR
		printf("addr/type: %lu/%c\n", addr, access_type);

		printf("val (%ld):", val_count);
		for (ssize_t i = 0; i < val_count; ++i) {
			printf("%lu ", val[i]);
		}

		if (val != NULL) {
			free(val);
			val = NULL;
		}
		printf("\n");
#endif

}
uint32_t read_pid_value(uint32_t a_addr) {
//uint32_t read_pid_value(uint32_t a_addr) {
	void* virt_addr = map_base + (a_addr & MAP_MASK);
	uint32_t read_result = 0;
	read_result = *((uint32_t *) virt_addr);
	// the slow DAC values will always be positive, so transform fast DAC only

	int last_three_digits = a_addr % 1000;

	if(last_three_digits >= 296 && last_three_digits < 360) {
		// fast PIDs, not int reset
		if(read_result > 8191) read_result = read_result - 16384;
	}

	if(last_three_digits >= 360 && last_three_digits <= 420 ) {
		// slow PIDs, not int reset
		if(read_result > 2047) read_result = read_result - 4096;
	}

	if(last_three_digits == 468 || last_three_digits == 484 || last_three_digits == 500 || last_three_digits == 516) {
		// integrator frequency conversion - fast PIDS
		read_result = 125000000 / (read_result + 1);
	}

	if(last_three_digits == 532 || last_three_digits == 548 || last_three_digits == 564 || last_three_digits == 580) {
		// integrator frequency conversion- fast PIDS
		read_result = 100000 / (read_result + 1);
	}


	printf("%d\n", read_result);
	//printf("0x%08x\n", read_result);
	fflush(stdout);
//	printf("%i\n", a_addr%1000);

	return read_result;
}

uint32_t read_value(uint32_t a_addr) {
	void* virt_addr = map_base + (a_addr & MAP_MASK);
	uint32_t read_result = 0;
	read_result = *((uint32_t *) virt_addr);
//	printf("%d\n", read_result);
	printf("0x%08x\n", read_result);
	fflush(stdout);
	return read_result;
}

void write_values(unsigned long a_addr, int a_type, unsigned long* a_values, ssize_t a_len) {
	void* virt_addr = map_base + (a_addr & MAP_MASK);

	for (ssize_t i = 0; i < a_len; ++i) {
		switch(a_type) {
			case 'b':
				*((unsigned char *) virt_addr) = a_values[i];
				break;
			case 'h':
				*((unsigned short *) virt_addr) = a_values[i];
				break;
			case 'w':
				*((unsigned long *) virt_addr) = a_values[i];
				break;
		}
	}
	/*
	if (a_len == 1) {
		printf("Written 0x%lX\n", a_values[0]);
	}
	else {
		printf("Written %d values\n", a_len);
	}
	*/
	fflush(stdout);
}

int parse_from_stdin(unsigned long* a_addr, int* a_type, unsigned long** a_values, ssize_t* a_len) {
	char* line = NULL;
	size_t len = 0;
	ssize_t ret = 0;
	ssize_t val_count = 0;

	*a_addr = 0;
	*a_values = calloc(4*1024, sizeof(unsigned long));
	
	while ((ret = getline(&line, &len, stdin)) != -1) {
		if (line[0] == '\n') {
			break;
		}
		{
			char* token;
			token = strtok(line, " \t");
			if (token == NULL) {
				break;
			}
			if (*a_addr == 0) {
				*a_addr = strtoul(token, 0, 0);
				token = strtok(NULL, " \t");
				if (token == NULL) {
					break;
				}
				*a_type = tolower(token[0]);
			}
			else {
				(*a_values)[val_count] = strtoul(token, 0, 0);
				++val_count;
			}

			for (; ; ++val_count) {
				token = strtok(NULL, " \t");
				if (token == NULL)
					break;
				(*a_values)[val_count] = strtoul(token, 0, 0);
			}
		}
	}

	if (line) {
		free(line);
	}

	*a_len = val_count;
	
	if (ret == -1) {
		if (errno != 0) {
			FATAL;
		}
		else if (*a_addr != 0) {
			return val_count;
		}
		return -1;
	}
	else {
		return val_count;
	}
}

int parse_from_argv(int a_argc, char **a_argv, unsigned long* a_addr, int* a_type, unsigned long** a_values, ssize_t* a_len) {

	int val_count = 0;

	*a_addr = strtoul(a_argv[1], 0, 0);
	*a_values = calloc(4*1024, sizeof(unsigned long));

	//if (a_argc > 2) {
		*a_type = 'w';//tolower(a_argv[2][0]);
	//}

	for (int i = 2; i < a_argc; ++i, ++val_count) {
		(*a_values)[val_count] = strtoul(a_argv[i], 0, 0);
	}

	*a_len = val_count;
	return 0;
}

int parse_from_argv_par(int a_argc, char **a_argv, double** a_values, ssize_t* a_len) {

	int val_count = 0;
	*a_values = calloc(4*1024, sizeof(double));
	for (int i = 2; i < a_argc; ++i, ++val_count) {
		(*a_values)[val_count] = strtod(a_argv[i], 0);
	}
	*a_len = val_count;
	return 0;
}


