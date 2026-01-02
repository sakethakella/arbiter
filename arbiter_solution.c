#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <time.h>

// --- CONFIGURATION ---
#define N 32              // Number of Requesters (Scalable) [cite: 20]
#define MAX_CYCLES 1000  // Simulation duration

// --- THE ARBITER DESIGN (The Logic) ---
// State variable for Round-Robin pointer (Simulates a Register)
static int last_granted_index = N - 1; 

void arbiter_logic(int requests[N], int grants[N]) {
    // 1. Reset Grants (Default to 0)
    for (int i = 0; i < N; i++) grants[i] = 0;

    // 2. Round-Robin Selection
    // Start searching at (last_granted + 1) to avoid fixed priority [cite: 56]
    for (int offset = 1; offset <= N; offset++) {
        int current_idx = (last_granted_index + offset) % N;

        if (requests[current_idx]) {
            grants[current_idx] = 1;      // Issue Grant
            last_granted_index = current_idx; // Update Pointer
            return; // Exit immediately (Mutual Exclusion) 
        }
    }
    // If loop finishes without return, no requests were active.
}

// --- VERIFICATION UTILITIES ---

// CHECK 1: Mutual Exclusion
// Requirement: "At most one requester may be granted access" [cite: 12]
void check_mutual_exclusion(int grants[N], int cycle) {
    int total_grants = 0;
    for (int i = 0; i < N; i++) total_grants += grants[i];
    
    if (total_grants > 1) {
        printf("[ERROR] Cycle %d: Mutual Exclusion Violation! Grants issued: %d\n", cycle, total_grants);
        exit(1);
    }
}

// CHECK 2: Work Conservation
// Requirement: "If one or more requests are active, exactly one grant must be issued" [cite: 13]
void check_work_conservation(int requests[N], int grants[N], int cycle) {
    int active_requests = 0;
    int active_grants = 0;
    for (int i = 0; i < N; i++) {
        if (requests[i]) active_requests = 1;
        if (grants[i]) active_grants = 1;
    }

    if (active_requests && !active_grants) {
        printf("[ERROR] Cycle %d: Work Conservation Violation! Request active but no grant.\n", cycle);
        exit(1);
    }
}

// CHECK 3: Starvation / Fairness Monitor
// Requirement: "No requester may starve" [cite: 17]
// We track how long each active request has been waiting.
int wait_time[N] = {0}; // Scoreboard

void check_starvation(int requests[N], int grants[N], int cycle) {
    for (int i = 0; i < N; i++) {
        if (requests[i] && !grants[i]) {
            wait_time[i]++; // Request is waiting
        } else if (grants[i]) {
            wait_time[i] = 0; // Reset on grant
        } else {
            wait_time[i] = 0; // Request dropped (transient), reset counter
        }

        // Mathematical Proof: In Round-Robin with N agents, 
        // max wait time should never exceed N cycles if properly implemented.
        if (wait_time[i] > N) { 
            printf("[ERROR] Cycle %d: Starvation Detected! Agent %d waited %d cycles.\n", cycle, i, wait_time[i]);
            exit(1);
        }
    }
}

// --- MAIN SIMULATION LOOP ---
int main() {
    int requests[N];
    int grants[N];
    
    srand(time(NULL)); // Seed random generator

    printf("--- Starting Verification for N=%d ---\n", N);

    for (int cycle = 1; cycle <= MAX_CYCLES; cycle++) {
        // A. STIMULUS GENERATION
        // Randomly assert requests (50% chance for each) to simulate traffic
        for (int i = 0; i < N; i++) {
            requests[i] = rand() % 2; 
        }

        // Force a specific "Stress Test" scenario occasionally
        // Every 100 cycles, turn ON all requests to test strict round-robin
        if (cycle % 100 == 0) {
            for (int i = 0; i < N; i++) requests[i] = 1;
        }

        // B. EXECUTE DESIGN
        arbiter_logic(requests, grants);

        // C. VERIFY OUTPUTS (Automated Checkers)
        check_mutual_exclusion(grants, cycle);
        check_work_conservation(requests, grants, cycle);
        check_starvation(requests, grants, cycle);

        // D. VISUALIZATION (Print first 10 cycles only to avoid clutter)
        if (cycle <= 100) {
            printf("C%02d | Req: [ ", cycle);
            for(int i=0; i<N; i++) printf("%d", requests[i]);
            printf(" ] -> Gnt: [ ");
            for(int i=0; i<N; i++) printf("%d", grants[i]);
            printf(" ]\n");
        }
    }

    printf("\n--- SUCCESS: Passed %d cycles without violations. ---\n", MAX_CYCLES);
    printf("Verified: Mutual Exclusion, Work Conservation, Starvation Freedom.\n");
    return 0;
}