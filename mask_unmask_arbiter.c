// Software Implementation of a Round-Robin Arbiter, scalable up to large N
// NOTE: While C demonstrates sequential loops and hardware behaviour is usually parallel,
// this simulation indicates cycle-accurate behaviour.
// This is a behavioural reference model, not a gate-level implementation.

#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#define N 32 

// Pointer to track last granted requester
static int last_granted_index;

// Explicit reset function to stay relevant wrt hardware semantics
void arbiter_reset(void) {
    last_granted_index = N - 1;
}

void arbiter_logic_mask_unmask(int requests[N], int grants[N]) {
    for (int i = 0; i < N; i++) grants[i] = 0;
    int winner = -1;
    for (int i = last_granted_index + 1; i < N; i++) {
        if (requests[i] == 1) {
            winner = i;
            break;
        }
    }

    // Wrap-around scan 
    if (winner == -1) {
        for (int i = 0; i <= last_granted_index; i++) {
            if (requests[i] == 1) {
                winner = i;
                break;
            }
        }
    }

    // Grant/update pointer only if a request exists
    if (winner != -1) {
        grants[winner] = 1;
        last_granted_index = winner;
    }
}

void print_bits(int *vec) {
    printf("[ ");
    for (int i = N - 1; i >= 0; i--) {
        printf("%d", vec[i]);
    }
    printf(" ]");
}

int main() {
    int req[N];
    int gnt[N];

    srand(time(NULL));

    arbiter_reset();

    printf("--- Mask/Unmask Arbiter Verification (N=%d) ---\n\n", N);

    // Run 100 cycles
    for (int cycle = 1; cycle <= 100; cycle++) {
        for (int i = 0; i < N; i++) {
            req[i] = rand() % 2;
        }

        arbiter_logic_mask_unmask(req, gnt);

        printf("C%02d | Req: ", cycle);
        print_bits(req);
        printf(" -> Gnt: ");
        print_bits(gnt);
        printf("\n");
    }

    printf("\n[Special Check] Forcing Wrap-Around...\n");
    for (int i = 0; i < N; i++) req[i] = 0;
    req[0] = 1;

    arbiter_reset();

    arbiter_logic_mask_unmask(req, gnt);

    printf("State=Last, Req=[0] -> Gnt: ");
    print_bits(gnt);
    printf("\n");

    return 0;
}

