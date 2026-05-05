-- PostgreSQL Schema for HR Employee and Payroll
-- Character Set: UTF8 (supports Thai characters)

CREATE TABLE hrEmployee (
    EmployeeID   VARCHAR(36)   COLLATE "C" NOT NULL,
    FirstName    VARCHAR(100)  NOT NULL,
    LastName     VARCHAR(100)  NOT NULL,
    Email        VARCHAR(150)  NULL,
    Department   VARCHAR(100)  NULL,
    Position     VARCHAR(100)  NULL,
    HireDate     DATE          NULL,
    IsActive     SMALLINT      NOT NULL DEFAULT 1,

    PRIMARY KEY (EmployeeID)
);

-- Create index for foreign key reference
CREATE INDEX idx_employee_id ON hrEmployee(EmployeeID);

CREATE TABLE hrPayroll_Details (
    PayrollID              UUID              NOT NULL DEFAULT gen_random_uuid(),
    EmployeeID             VARCHAR(36)       COLLATE "C" NOT NULL,
    BaseSalary             NUMERIC(19, 2)    NULL,
    TaxRate                NUMERIC(5, 2)     NULL,
    SocialSecurityFund     NUMERIC(18, 4)    NULL,
    OT_Rate                FLOAT8            NULL,
    PaymentMethod          INTEGER           NOT NULL,
    IsTaxExempt            SMALLINT          DEFAULT 0,
    LastPaymentTimestamp   TIMESTAMP WITH TIME ZONE NULL DEFAULT CURRENT_TIMESTAMP,
    PayrollNote            TEXT              NULL,

    PRIMARY KEY (PayrollID),
    FOREIGN KEY (EmployeeID) REFERENCES hrEmployee(EmployeeID) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Create indexes for better query performance
CREATE INDEX idx_payroll_employee ON hrPayroll_Details(EmployeeID);
CREATE INDEX idx_payroll_timestamp ON hrPayroll_Details(LastPaymentTimestamp);
