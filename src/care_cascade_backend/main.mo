import TrieMap "mo:base/TrieMap";
import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Error "mo:base/Error";

// Define types for patient records, insurance claims, and Health ATM transactions
type Patient = {
  id: Text;
  name: Text;
  medicalHistory: [Text];
  insuranceProvider: Text;
  authorizedProviders: [Principal];
};

type InsuranceClaim = {
  patientId: Text;
  amount: Nat;
  status: ClaimStatus;
};

type HealthATMTransaction = {
  atmId: Text;
  patientId: Text;
  serviceProvided: Text;
  date: Time;
};

type ClaimStatus = {
  #Pending : Null;
  #Approved : Null;
  #Rejected : Null;
};

// Define the actor
actor CareCascade {
  // Store patient records, insurance claims, and Health ATM transactions
  var patients: TrieMap.Text<Patient> = TrieMap.empty();
  var insuranceClaims: TrieMap.Text<InsuranceClaim> = TrieMap.empty();
  var atmTransactions: TrieMap.Text<HealthATMTransaction> = TrieMap.empty();

  // Function to register a patient
  public func registerPatient(patient: Patient): async () {
    patients.put(patient.id, patient);
  }

  // Function to update patient records (by authorized providers only)
  public func updateMedicalRecord(patientId: Text, newRecord: Text): async () {
  let caller = await Actor.caller();
  let patientOpt = patients.get(patientId);
  switch (patientOpt) {
    case (?p) {
      if (p.authorizedProviders.contains(caller) or p.insuranceProvider == Principal.toText(caller)) {
        let updatedPatient = { 
          ...p, 
          medicalHistory = p.medicalHistory # [newRecord]
        };
        patients.put(patientId, updatedPatient);
      } else {
        throw Error.reject("Unauthorized access");
      }
    };
    case (_) {
      throw Error.reject("Patient not found");
    };
  }
}

  // Function to submit an insurance claim
  public func submitInsuranceClaim(claim: InsuranceClaim): async () {
    insuranceClaims.put(claim.patientId, claim);
  }

  // Function to process insurance claims (only by the insurance provider)
  public func processClaim(patientId: Text, status: ClaimStatus): async () {
    let caller = await Actor.caller();
    let claimOpt = insuranceClaims.get(patientId);
    switch (claimOpt) {
      case (?c) {
        let patientOpt = patients.get(patientId);
        switch (patientOpt) {
          case (?p) {
            if (p.insuranceProvider == Principal.toText(caller)) {
              let updatedClaim = { ...c, status = status };
              insuranceClaims.put(patientId, updatedClaim);
            } else {
              throw Error.reject("Unauthorized access");
            }
          };
          case (_) {
            throw Error.reject("Patient not found");
          }
        }
      };
      case (_) {
        throw Error.reject("Claim not found");
      }
    }
  }

  // Function to log a Health ATM transaction
  public func logATMTransaction(transaction: HealthATMTransaction): async () {
    atmTransactions.put(transaction.patientId # transaction.date.toString(), transaction);
  }

  // Function to get a patient's medical history (by authorized personnel)
  public func getMedicalHistory(patientId: Text): async [Text] {
    let caller = await Actor.caller();
    let patientOpt = patients.get(patientId);
    switch (patientOpt) {
      case (?p) {
        if (p.authorizedProviders.contains(caller) or p.insuranceProvider == Principal.toText(caller)) {
          return p.medicalHistory;
        } else {
          throw Error.reject("Unauthorized access");
        }
      };
      case (_) {
        throw Error.reject("Patient not found");
      }
    }
  }

  // Function to authorize new healthcare providers for a patient
  public func authorizeProvider(patientId: Text, provider: Principal): async () {
    let patientOpt = patients.get(patientId);
    switch (patientOpt) {
      case (?p) {
        let updatedPatient = {
          ...p,
          authorizedProviders = p.authorizedProviders # [provider]
        };
        patients.put(patientId, updatedPatient);
      };
      case (_) {
        throw Error.reject("Patient not found");
      }
    }
  }
}
