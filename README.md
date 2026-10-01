# szcore_society

SzCore organization management: boss UI, online/offline membership, hire/fire, grades, society bank account and transaction history.

Dependencies: `oxmysql`, `szcore`, `szcore_ui`.

Public exports: `EnsureSociety`, `GetSociety`, `Deposit`, `Withdraw`, `Hire`, `Fire`, `SetGrade`, `GetTransactions`.

All management mutations are validated server-side.
