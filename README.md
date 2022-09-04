# 1D Time Domain Convolution

In this project our main goal is to exploit parallelism, create a custom circuit, implement it on the zed board, and interface them in different operating frequencies. The project work is divided into two parts. In one part, the main objective is to develop a DRAM read interface (address generator, FIFO, and control interface) and in another part to design a user app (signal buffer, kernel buffer). DRAM read entity runs on two clock domains (DRAM clock and User clock domain) and user app runs on user clock domain. These two in different frequency have been interfaced, and the DRAM read interface is used to send data to the user app from read memory. User app sends convolution results to DRAM write interface.

**Part 1: DRAM DMA Interface**

The DMA read interface has been created to read signal input data from DRAM into the convolution pipeline and for that, an address generator, a FIFO, a DMA controller, handshake between two clock domain and a DMA interface to interact with other DMA components
have been created. 

	1. Controller : It controls the registers storing size and start address. When Go signal is asserted, this value is passed through handshake to enable the size and address registers in the address generator. When the address generator receives the go signal, it means that the size and start address it receives from the user clock domain is valid and the address generator starts its counter to generate addresses for reading data from DRAM.
	
	2. Handshake : It creates a handshaking of the go signal from the user clock domain to the DRAM clock domain.
	
	3. FIFO : This FIFO receives data from DRAM located in DRAM clock domain and sends data to user app located in user clock domain. It is generated from Vivado.
	
	4. Address Generator : We have created an FSM for address generator that receives total number of size and start address from user app for which the address generator starts generating addresses. The size it receives is corresponding to 16-bit data of memory. But the generated address corresponds to 32-bit data of RAM. So, the FSM will divide the given sizein half (if size is even) or ceil of half (if size is odd). After receiving the go signal from the handshake, the address generator generates address. When go=1, it flushes all its data if has any. After that dram_rd_en and dram_ready signals are asserted, and the generated address are sent to the dram_read_addr. However, in case FIFO is full and the address generator already generated some address, data will be read from RAM for the extra addresses and those data will be lost. To avoid this issue a programmable full signal is used in our project which gets asserted when FIFO is full to the threshold given for programmable full flag which is 48 entries.

	5. Counter :  To ensure the assertion of done signal, a counter is placed in the user clock domain. When rd_en = 1 and FIFO is not empty it counts to ‘size’ and when it reaches to size done signal is asserted.

**Part 2: User app**

User app consists of convolution pipeline, which is provided, a signal buffer and kernel buffer to be implemented.

	1. Convolution Pipeline: Convolution pipeline is basically a multiplier adder tree. It takes two input arrays from signal buffer and kernel buffer. The corresponding elements in the input array are multiplied and then added up all the multiplied output through an adder tree. The signal buffer acts as a sliding window. The kernel buffer remains the same through the whole process whereas the inputs coming from the signal buffer changes by one value through a sliding window. During the whole convolution process, there is a chance that the output is greater than 16 bits, in that case we clipped the output to be all ‘1’. Like the input the output of the multiplier adder tree is sent to DRAM which reads it and send it to the memory map. For this purpose, valid_in = 1 is instantiated on upon the full of kernel buffer, read_en is high for the signal buffer and the DRAM1 interface is ready to read. Then we waited for 135 cycles using a delay entity and after that asserted the valid_out signal informing the DRAM_1 interface that the send data is valid.

	2. Signal Buffer: A signal buffer is designed with 16 bits input. It takes data when the wr_en is high and shifts it along the registers. The window size is equal to the buffer size as we have to read it whole together. During the process it is made sure that the wr_en is asserted onlywhen the ram1_wr_ready is ready. There is a full flag (signal_full) that goes high when all the registers are filled. Similarly, a read_en signal is asserted when the data transfers into the pipeline. At this time signal_empty is asserter to empty the signal buffer and make room for the next set of data in window by shifting. A counter is also maintained to check the number of times read and write enable assertion. The full and empty flags are asserted based on this counter activity, i.e., full when counter value equals buffer size and empty when value is less than buffer size. 
	
	3. Kernel Buffer: The design of the kernel buffer is like the signal buffer, the only difference is that it takes input value only once, not sliding as signal buffer and no new value in every cycle. Similar to signal buffer it also consists of 128 16-bit registers. Kernel buffer also has full and empty flag as signal buffer. The full signal (kernal_full) ensures that the kernel buffer is full of data and the empty signal that the data has transferred to the pipeline. The data is read from kernel buffer via read enable signal (kernal_rd_en) which is asserted only when DRAM1 interface is ready(ram1_wr_ready) and the kernel buffer is full (kernal_full).


Note: Only the VHDL codes are uploaded in the github repository. Other codes (DRAM read & write codes are not included here).
