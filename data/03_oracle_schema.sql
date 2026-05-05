-- Oracle Schema for HR Employee and Payroll
-- Character Set: AL32UTF8 (supports Thai characters)

-- Drop tables if they exist (optional)
-- DROP TABLE hrPayroll_Details;
-- DROP TABLE hrEmployee;

CREATE TABLE hrEmployee (
    EmployeeID   VARCHAR2(36)   NOT NULL,
    FirstName    NVARCHAR2(100) NOT NULL,
    LastName     NVARCHAR2(100) NOT NULL,
    Email        NVARCHAR2(150) NULL,
    Department   NVARCHAR2(100) NULL,
    Position     NVARCHAR2(100) NULL,
    HireDate     DATE           NULL,
    IsActive     NUMBER(1)      NOT NULL DEFAULT 1,

    CONSTRAINT pk_employee PRIMARY KEY (EmployeeID)
);

-- Create index for employee ID
CREATE INDEX idx_employee_id ON hrEmployee(EmployeeID);

CREATE TABLE hrPayroll_Details (
    PayrollID              VARCHAR2(36)          NOT NULL DEFAULT SYS_GUID(),
    EmployeeID             VARCHAR2(36)          NOT NULL,
    BaseSalary             NUMBER(19, 2)         NULL,
    TaxRate                NUMBER(5, 2)          NULL,
    SocialSecurityFund     NUMBER(18, 4)         NULL,
    OT_Rate                BINARY_FLOAT          NULL,
    PaymentMethod          NUMBER(10)            NOT NULL,
    IsTaxExempt            NUMBER(1)             DEFAULT 0,
    LastPaymentTimestamp   TIMESTAMP WITH TIME ZONE NULL DEFAULT SYSTIMESTAMP,
    PayrollNote            CLOB                  NULL,

    CONSTRAINT pk_payroll PRIMARY KEY (PayrollID),
    CONSTRAINT fk_payroll_employee FOREIGN KEY (EmployeeID) REFERENCES hrEmployee(EmployeeID) ON DELETE CASCADE
);

-- Create indexes for better query performance
CREATE INDEX idx_payroll_employee ON hrPayroll_Details(EmployeeID);
CREATE INDEX idx_payroll_timestamp ON hrPayroll_Details(LastPaymentTimestamp);

-- Create sequence for generating IDs (optional alternative)
-- CREATE SEQUENCE seq_payroll_id START WITH 1 INCREMENT BY 1;
