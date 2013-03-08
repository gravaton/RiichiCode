#include <stdio.h>


void output(int* tiles) {
	int i = 0;

	for(i = 0; i < 34; i++) {
		printf("%d",tiles[i]);
	}
	printf("\n");
}

int increment(int* tiles) {
	int* worker = tiles + 33;
	static int sum = 0;

	do {
		worker = tiles + 33;
		while(*worker == 5) {
			(*worker) = 0;
			sum -= 3;
			worker--;
			if(worker == tiles) { return -1; }
		}
		sum += (*worker == 4 ? -1 : 1);
		(*worker)++;
	} while (sum != 14);
	
	return 1;
}

int main() {
	int tiles[34];
	int i = 0;

	for(i = 0; i < 34; i++) {
		tiles[i] = 0;
	}
	printf("INITIALIZED!\n");
	output(tiles);
	while(increment(tiles) == 1) {
		output(tiles); 
	}
}
