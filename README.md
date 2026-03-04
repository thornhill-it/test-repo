# 🧹 AWS S3 Security Janitor 
### *Automated Event-Driven Remediation & Governance*

---

## 🏗️ Architecture & OODA Loop

```text
[  OBSERVE  ] -> S3:PutBucketPolicy (Public Detection via CloudTrail)
       | 
[  ORIENT   ] -> EventBridge Rule (Pattern Match & JSON Parsing)
       | 
[  DECIDE   ] -> Lambda Logic (Verify Public Status & Region)
       | 
[    ACT    ] -> Boto3:PutBucketPublicAccessBlock (Remediation)
```

The framework follows a reactive security loop:
1. **Detect:** AWS CloudTrail captures a security event.
2. **Filter:** Amazon EventBridge identifies the violation.
3. **Remediate:** AWS Lambda enforces the security baseline.

---

## 🧪 Evidence of Remediation (The "Chaos Test")
### CloudWatch Validation

### 📜 Automated Audit Trail (CloudWatch)
![Remediation Proof](evidence-gallery/15-remediation-log.png)
*The "Smoking Gun": This log verifies the Janitor identified the drift and successfully enforced the security policy via PutBucketPublicAccessBlock in near real-time.*

---

## 💎 Engineering Insights
* **Static Backend:** Hardcoded region in `provider.tf` to satisfy Terraform's initialization requirements.
* **Least-Privilege:** Custom IAM policies to prevent automation "over-reach."
* **Secret Scrubbing:** Strict Git-flow to prevent `.env` and `.tfvars` leakage.

---

## 🔧 Technical Stack
* **Infrastructure:** Terraform (HCL)
* **Runtime:** Python 3.13 (Boto3)
* **Governance:** EventBridge & CloudWatch

---

## 🔮 Future Roadmap (Scaling & Retroactivity)
* **Historical Remediation:** Currently, the Janitor is **Event-Driven** to maintain a "Zero-Read" security posture. A future iteration would include an **AWS Config** trigger to perform a one-time "historical sweep" of buckets created before the Janitor was deployed.
* **Multi-Account Orchestration:** Expanding the EventBridge bus to aggregate security events from a multi-account AWS Organization.
