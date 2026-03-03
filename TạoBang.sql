-- ===================================================================
-- DIGITALVILLAGEDB - FULL REWRITE (VỚI ĐỊA CHỈ & THÔNG TIN CHỦ SỞ HỮU)
-- Không trigger / Không procedure / Không function
-- Ngôn ngữ: Tiếng Việt (nội dung dữ liệu mẫu)
-- Target: SQL Server 2022
-- ===================================================================

IF DB_ID('DigitalVillageDB') IS NOT NULL
BEGIN
    ALTER DATABASE DigitalVillageDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DigitalVillageDB;
END
GO

CREATE DATABASE DigitalVillageDB;
GO

USE DigitalVillageDB;
GO

-- Tạo schema
EXEC('CREATE SCHEMA iot');
EXEC('CREATE SCHEMA esg');
EXEC('CREATE SCHEMA commerce');
EXEC('CREATE SCHEMA community');
EXEC('CREATE SCHEMA gamify');
EXEC('CREATE SCHEMA ai');
EXEC('CREATE SCHEMA logistics');
EXEC('CREATE SCHEMA media');
EXEC('CREATE SCHEMA core'); -- schema phụ chứa address, contact
GO

/* =======================================================================
   CORE: Users, Address, Profiles (cập nhật thêm Address/Contact)
   ======================================================================= */
CREATE TABLE core.UserAddresses (
    AddressId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    UserId UNIQUEIDENTIFIER NOT NULL,
    Province NVARCHAR(100),
    District NVARCHAR(100),
    Commune NVARCHAR(100),
    AddressLine NVARCHAR(300),
    CreatedAt DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET()
);

CREATE TABLE dbo.Users (
    UserId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    PhoneNumber VARCHAR(20) UNIQUE NOT NULL,
    Email VARCHAR(200) UNIQUE NULL,
    PasswordHash VARBINARY(512) NOT NULL,
    RoleType VARCHAR(20) NOT NULL CHECK (RoleType IN ('FARMER','SME','COMMUNITY','ADMIN')),
    CreatedAt DATETIMEOFFSET NOT NULL DEFAULT SYSDATETIMEOFFSET(),
    IsActive BIT NOT NULL DEFAULT 1,
    DisplayName NVARCHAR(200) NULL
);

CREATE TABLE dbo.FarmerProfiles (
    UserId UNIQUEIDENTIFIER PRIMARY KEY FOREIGN KEY REFERENCES dbo.Users(UserId),
    FullName NVARCHAR(200) NOT NULL,
    Village NVARCHAR(200) NULL,
    ContactName NVARCHAR(200) NULL,
    ContactPhone VARCHAR(20) NULL,
    PreferredVoice BIT DEFAULT 1
);

CREATE TABLE dbo.SMEProfiles (
    UserId UNIQUEIDENTIFIER PRIMARY KEY FOREIGN KEY REFERENCES dbo.Users(UserId),
    CompanyName NVARCHAR(300) NOT NULL,
    TaxCode VARCHAR(50) UNIQUE NOT NULL,
    ContactName NVARCHAR(200) NULL,
    ContactPhone VARCHAR(20) NULL,
    AddressSummary NVARCHAR(300) NULL,
    TotalESGScore DECIMAL(7,2) DEFAULT 0.00,
    ImpactInvestmentFund DECIMAL(18,2) DEFAULT 0.00
);

CREATE TABLE community.CommunityProfiles (
    UserId UNIQUEIDENTIFIER PRIMARY KEY FOREIGN KEY REFERENCES dbo.Users(UserId),
    Nickname NVARCHAR(100) NULL,
    GamificationPoints INT DEFAULT 0,
    VolunteerHistory NVARCHAR(MAX) NULL,
    MicroInvestmentPortfolio NVARCHAR(MAX) NULL
);

/* =======================================================================
   IOT: Farms, Devices, Readings, FarmingLogs
   ======================================================================= */
CREATE TABLE iot.Farms (
    FarmId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    FarmerId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES dbo.FarmerProfiles(UserId),
    FarmName NVARCHAR(200),
    Boundary GEOGRAPHY NULL,
    Location GEOGRAPHY NULL, -- điểm trung tâm
    AreaHectares DECIMAL(9,2) NOT NULL,
    CropType NVARCHAR(100),
    Certifications NVARCHAR(200) NULL,
    OwnerContact NVARCHAR(200) NULL
);

CREATE TABLE iot.IoTDevices (
    DeviceId VARCHAR(50) PRIMARY KEY,
    FarmId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES iot.Farms(FarmId),
    DeviceType VARCHAR(50) CHECK (DeviceType IN ('SOIL','AIR','WATER','GATEWAY')),
    BatteryLevel TINYINT CHECK (BatteryLevel BETWEEN 0 AND 100),
    Coordinates GEOGRAPHY NULL,
    LastSeen DATETIMEOFFSET NULL,
    InstalledAt DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET()
);

CREATE TABLE iot.IoTSensorReadings (
    ReadingId BIGINT IDENTITY(1,1) PRIMARY KEY,
    DeviceId VARCHAR(50) NOT NULL FOREIGN KEY REFERENCES iot.IoTDevices(DeviceId),
    MetricType VARCHAR(50) NOT NULL,
    MetricValue DECIMAL(18,6) NOT NULL,
    RecordedAt DATETIMEOFFSET NOT NULL DEFAULT SYSDATETIMEOFFSET()
);
CREATE NONCLUSTERED INDEX IX_IoTSensorReadings_Device_Metric_Time ON iot.IoTSensorReadings(DeviceId, MetricType, RecordedAt DESC);

CREATE TABLE iot.FarmingLogs (
    LogId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    FarmId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES iot.Farms(FarmId),
    ActorUserId UNIQUEIDENTIFIER NULL FOREIGN KEY REFERENCES dbo.Users(UserId),
    ActionType NVARCHAR(200) NOT NULL,
    RawVoiceText NVARCHAR(2000) NULL,
    MaterialUsed NVARCHAR(200) NULL,
    MaterialQrCode VARCHAR(200) NULL,
    Quantity DECIMAL(18,4) NULL,
    RecordedAt DATETIMEOFFSET NOT NULL DEFAULT SYSDATETIMEOFFSET()
);

/* =======================================================================
   ESG & CARBON: Catalog, MRV, Evidence, Ledger, Scores
   ======================================================================= */
CREATE TABLE esg.CarbonImpactCatalog (
    FactorId INT IDENTITY(1,1) PRIMARY KEY,
    ActivityName NVARCHAR(200) NOT NULL,
    Unit VARCHAR(50) NOT NULL,
    EmissionFactor DECIMAL(18,6) NOT NULL,
    SourceReference NVARCHAR(500) NULL
);

CREATE TABLE esg.MRVLogs (
    MRVId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    FarmId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES iot.Farms(FarmId),
    FactorId INT NOT NULL FOREIGN KEY REFERENCES esg.CarbonImpactCatalog(FactorId),
    ActivityValue DECIMAL(18,6) NOT NULL,
    CalculatedCO2e DECIMAL(18,6) NULL,
    VerificationStatus VARCHAR(20) DEFAULT 'PENDING' CHECK (VerificationStatus IN ('PENDING','VERIFIED','REJECTED')),
    VerifiedAt DATETIMEOFFSET NULL,
    CreatedAt DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET()
);

CREATE TABLE esg.MRVEvidence (
    EvidenceId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    MRVId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES esg.MRVLogs(MRVId),
    FarmingLogId UNIQUEIDENTIFIER NULL FOREIGN KEY REFERENCES iot.FarmingLogs(LogId),
    SensorReadingId BIGINT NULL FOREIGN KEY REFERENCES iot.IoTSensorReadings(ReadingId),
    ProductBatchId UNIQUEIDENTIFIER NULL,
    EvidenceType VARCHAR(50) NULL,
    AttachedFile NVARCHAR(400) NULL,
    CreatedAt DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET()
);

CREATE TABLE esg.CarbonLedger (
    TokenId VARCHAR(100) PRIMARY KEY,
    MRVId UNIQUEIDENTIFIER UNIQUE FOREIGN KEY REFERENCES esg.MRVLogs(MRVId),
    OwnerSMEId UNIQUEIDENTIFIER FOREIGN KEY REFERENCES dbo.SMEProfiles(UserId),
    TonsOfCO2e DECIMAL(18,6) NOT NULL,
    BlockchainTxHash VARCHAR(256) UNIQUE NULL,
    MintedAt DATETIMEOFFSET NOT NULL DEFAULT SYSDATETIMEOFFSET()
)
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = esg.CarbonLedgerHistory), LEDGER = ON);

CREATE TABLE esg.TokenOrders (
    OrderId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    TokenId VARCHAR(100) NOT NULL FOREIGN KEY REFERENCES esg.CarbonLedger(TokenId),
    SellerSMEId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES dbo.SMEProfiles(UserId),
    OrderType VARCHAR(10) NOT NULL CHECK (OrderType IN ('SELL','BUY')),
    Quantity DECIMAL(18,6) NOT NULL,
    PricePerTon DECIMAL(18,2) NOT NULL,
    Status VARCHAR(20) DEFAULT 'OPEN',
    CreatedAt DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET()
);

CREATE TABLE esg.TokenTrades (
    TradeId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    BuyOrderId UNIQUEIDENTIFIER NULL FOREIGN KEY REFERENCES esg.TokenOrders(OrderId),
    SellOrderId UNIQUEIDENTIFIER NULL FOREIGN KEY REFERENCES esg.TokenOrders(OrderId),
    TokenId VARCHAR(100) NULL,
    Quantity DECIMAL(18,6) NOT NULL,
    PricePerTon DECIMAL(18,2) NOT NULL,
    TradeAt DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET()
);

CREATE TABLE esg.EscrowAccounts (
    EscrowId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    OrderId UNIQUEIDENTIFIER FOREIGN KEY REFERENCES esg.TokenOrders(OrderId),
    Amount DECIMAL(18,2) NOT NULL,
    Status VARCHAR(30) DEFAULT 'HELD'
);

CREATE TABLE esg.SMESustainabilityScores (
    ScoreId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    SMEId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES dbo.SMEProfiles(UserId),
    EnvironmentalScore DECIMAL(5,2) NOT NULL,
    SocialScore DECIMAL(5,2) NOT NULL,
    GovernanceScore DECIMAL(5,2) NOT NULL,
    TotalScore AS ((EnvironmentalScore + SocialScore + GovernanceScore) / 3.0) PERSISTED,
    Rating VARCHAR(10) NULL,
    EvaluationNote NVARCHAR(1000) NULL,
    EvaluatedAt DATETIMEOFFSET NOT NULL DEFAULT SYSDATETIMEOFFSET()
);

/* =======================================================================
   LOGISTICS / AGRI-UBER
   ======================================================================= */
CREATE TABLE logistics.AgriMachines (
    MachineId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    OwnerId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES dbo.Users(UserId),
    MachineType NVARCHAR(100) NOT NULL,
    BasePricePerHour DECIMAL(18,2) NOT NULL,
    ContactName NVARCHAR(200) NULL,
    ContactPhone VARCHAR(20) NULL,
    LastKnownLocation GEOGRAPHY NULL
);

CREATE TABLE logistics.MachineHailingRequests (
    RequestId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    FarmId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES iot.Farms(FarmId),
    MachineTypeRequired NVARCHAR(100) NOT NULL,
    ExpectedStartTime DATETIMEOFFSET NOT NULL,
    TargetArea GEOGRAPHY NOT NULL,
    Status VARCHAR(20) DEFAULT 'MATCHING' CHECK (Status IN ('MATCHING','ACCEPTED','COMPLETED')),
    AssignedMachineId UNIQUEIDENTIFIER NULL FOREIGN KEY REFERENCES logistics.AgriMachines(MachineId),
    RequesterContact NVARCHAR(200) NULL,
    CreatedAt DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET()
);
CREATE SPATIAL INDEX SPNDX_Hailing_TargetArea ON logistics.MachineHailingRequests(TargetArea);

/* =======================================================================
   MICRO INSURANCE
   ======================================================================= */
CREATE TABLE esg.MicroInsuranceContracts (
    ContractId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    FarmId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES iot.Farms(FarmId),
    CoverageAmount DECIMAL(18,2) NOT NULL,
    TriggerMetric VARCHAR(50) NOT NULL,
    TriggerThreshold DECIMAL(18,6) NOT NULL,
    BeneficiaryName NVARCHAR(200) NULL,
    BeneficiaryAccount VARCHAR(200) NULL,
    Status VARCHAR(20) DEFAULT 'ACTIVE' CHECK (Status IN ('ACTIVE','PAYOUT_TRIGGERED','EXPIRED')),
    CreatedAt DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET()
);

CREATE TABLE esg.InsurancePayoutLogs (
    PayoutId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    ContractId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES esg.MicroInsuranceContracts(ContractId),
    TriggeredByReadingId BIGINT NULL FOREIGN KEY REFERENCES iot.IoTSensorReadings(ReadingId),
    TriggerMetric VARCHAR(50),
    TriggerValue DECIMAL(18,6),
    PayoutAmount DECIMAL(18,2) NULL,
    TriggeredAt DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET(),
    ProcessedOnChain BIT DEFAULT 0
);

/* =======================================================================
   MARKETPLACE, VOUCHER, CROWDFUNDING
   ======================================================================= */
CREATE TABLE commerce.Products (
    ProductId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    SellerId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES dbo.Users(UserId),
    Title NVARCHAR(300) NOT NULL,
    Description NVARCHAR(MAX) NULL,
    Category NVARCHAR(100) NULL,
    Price DECIMAL(18,2) NOT NULL,
    Unit NVARCHAR(50) NULL,
    IsGreen BIT DEFAULT 1,
    CreatedAt DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET()
);

CREATE TABLE commerce.ProductBatches (
    ProductBatchId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    ProductId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES commerce.Products(ProductId),
    BatchCode VARCHAR(200) UNIQUE,
    ProductionDate DATE NULL,
    Metadata NVARCHAR(1000) NULL
);

CREATE TABLE commerce.Orders (
    OrderId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    BuyerId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES dbo.Users(UserId),
    OrderTotal DECIMAL(18,2) NOT NULL,
    Status VARCHAR(50) DEFAULT 'CREATED',
    CreatedAt DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET()
);

CREATE TABLE commerce.OrderItems (
    OrderItemId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    OrderId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES commerce.Orders(OrderId),
    ProductId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES commerce.Products(ProductId),
    Quantity DECIMAL(18,4) NOT NULL,
    Price DECIMAL(18,2) NOT NULL
);

CREATE TABLE commerce.Payments (
    PaymentId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    OrderId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES commerce.Orders(OrderId),
    Amount DECIMAL(18,2) NOT NULL,
    Provider VARCHAR(100),
    ProviderReference VARCHAR(200),
    PaidAt DATETIMEOFFSET
);

CREATE TABLE commerce.Certificates (
    CertificateId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    SellerId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES dbo.Users(UserId),
    CertificateType VARCHAR(200),
    DocumentUrl NVARCHAR(500),
    UploadedAt DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET()
);

CREATE TABLE commerce.FundingLogs (
    FundingId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    FromSMEId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES dbo.SMEProfiles(UserId),
    ToFarmId UNIQUEIDENTIFIER NULL FOREIGN KEY REFERENCES iot.Farms(FarmId),
    Amount DECIMAL(18,2) NOT NULL,
    Purpose NVARCHAR(500) NULL,
    CreatedAt DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET()
);

CREATE TABLE commerce.Vouchers (
    VoucherId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    FundingId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES commerce.FundingLogs(FundingId),
    Code VARCHAR(100) UNIQUE NOT NULL,
    Catalog NVARCHAR(200) NOT NULL,
    Quantity INT DEFAULT 1,
    ExpiresAt DATETIMEOFFSET NULL
);

CREATE TABLE commerce.VoucherRedemptions (
    RedemptionId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    VoucherId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES commerce.Vouchers(VoucherId),
    RedeemedBy UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES dbo.Users(UserId),
    RedeemedAt DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET()
);

CREATE TABLE commerce.CropInvestments (
    CampaignId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    FarmId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES iot.Farms(FarmId),
    Title NVARCHAR(300),
    GoalAmount DECIMAL(18,2),
    CollectedAmount DECIMAL(18,2) DEFAULT 0,
    StartDate DATE,
    EndDate DATE,
    CreatedAt DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET()
);

CREATE TABLE commerce.Investments (
    InvestmentId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    CampaignId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES commerce.CropInvestments(CampaignId),
    InvestorId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES dbo.Users(UserId),
    Amount DECIMAL(18,2) NOT NULL,
    InvestedAt DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET()
);

/* =======================================================================
   AGRI-WASTE, LAND BANK, CONSULTING
   ======================================================================= */
CREATE TABLE commerce.AgriWasteListings (
    ListingId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    SellerId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES dbo.Users(UserId),
    Title NVARCHAR(300),
    Description NVARCHAR(MAX),
    Quantity DECIMAL(18,4),
    Unit NVARCHAR(50),
    Price DECIMAL(18,2),
    CreatedAt DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET()
);

CREATE TABLE commerce.LandListings (
    LandId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    OwnerId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES dbo.Users(UserId),
    Location GEOGRAPHY NOT NULL,
    AreaHectares DECIMAL(9,2) NOT NULL,
    PricePerHectare DECIMAL(18,2) NULL,
    IsForRent BIT DEFAULT 1,
    CreatedAt DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET()
);

CREATE TABLE commerce.LandRentals (
    RentalId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    LandId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES commerce.LandListings(LandId),
    RenterId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES dbo.Users(UserId),
    StartDate DATE,
    EndDate DATE,
    Price DECIMAL(18,2)
);

CREATE TABLE community.ConsultingCases (
    CaseId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    FarmerId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES dbo.FarmerProfiles(UserId),
    ExpertId UNIQUEIDENTIFIER NULL FOREIGN KEY REFERENCES dbo.Users(UserId),
    Title NVARCHAR(300),
    Description NVARCHAR(MAX),
    MediaUrl NVARCHAR(500),
    Fee DECIMAL(18,2) DEFAULT 0,
    Status VARCHAR(50) DEFAULT 'OPEN',
    CreatedAt DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET()
);

/* =======================================================================
   MEDIA, AI & DIGITAL TWIN
   ======================================================================= */
CREATE TABLE media.FarmMedia (
    MediaId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    FarmId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES iot.Farms(FarmId),
    UploadedBy UNIQUEIDENTIFIER NULL FOREIGN KEY REFERENCES dbo.Users(UserId),
    MediaType VARCHAR(50),
    Url NVARCHAR(500),
    Metadata NVARCHAR(2000),
    UploadedAt DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET()
);

CREATE TABLE ai.AIDetections (
    DetectionId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    MediaId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES media.FarmMedia(MediaId),
    ModelName NVARCHAR(200),
    Label NVARCHAR(200),
    Confidence DECIMAL(5,4),
    Notes NVARCHAR(1000),
    DetectedAt DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET()
);

CREATE TABLE ai.DigitalTwinSnapshots (
    SnapshotId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    FarmId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES iot.Farms(FarmId),
    SnapshotData NVARCHAR(MAX),
    CreatedAt DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET()
);

/* =======================================================================
   GAMIFICATION
   ======================================================================= */
CREATE TABLE gamify.SkyFarmItems (
    ItemId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    Name NVARCHAR(200),
    Description NVARCHAR(1000),
    Rarity VARCHAR(50),
    Price DECIMAL(18,2) NULL
);

CREATE TABLE gamify.SkyFarmPlots (
    PlotId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    OwnerId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES dbo.Users(UserId),
    LinkedFarmId UNIQUEIDENTIFIER NULL FOREIGN KEY REFERENCES iot.Farms(FarmId),
    VirtualCrop NVARCHAR(200),
    GrowthState INT DEFAULT 0,
    LastUpdated DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET()
);

CREATE TABLE gamify.GamificationPoints (
    EntryId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    UserId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES dbo.Users(UserId),
    Points INT NOT NULL,
    Reason NVARCHAR(500),
    CreatedAt DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET()
);

CREATE TABLE gamify.Achievements (
    AchievementId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    UserId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES dbo.Users(UserId),
    KeyName VARCHAR(200),
    AwardedAt DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET()
);

/* =======================================================================
   NOTIFICATIONS, ALERTS, AUDIT
   ======================================================================= */
CREATE TABLE dbo.NotificationChannels (
    ChannelId INT IDENTITY(1,1) PRIMARY KEY,
    Name VARCHAR(50),
    Config NVARCHAR(MAX)
);

CREATE TABLE dbo.Notifications (
    NotificationId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    UserId UNIQUEIDENTIFIER NULL FOREIGN KEY REFERENCES dbo.Users(UserId),
    ChannelId INT NULL FOREIGN KEY REFERENCES dbo.NotificationChannels(ChannelId),
    Title NVARCHAR(300),
    Body NVARCHAR(MAX),
    IsRead BIT DEFAULT 0,
    CreatedAt DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET()
);

CREATE TABLE dbo.Alerts (
    AlertId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    DeviceId VARCHAR(50) NULL FOREIGN KEY REFERENCES iot.IoTDevices(DeviceId),
    FarmId UNIQUEIDENTIFIER NULL FOREIGN KEY REFERENCES iot.Farms(FarmId),
    AlertType VARCHAR(200),
    Severity VARCHAR(20),
    Payload NVARCHAR(MAX),
    CreatedAt DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET(),
    IsResolved BIT DEFAULT 0
);

CREATE TABLE dbo.AuditLogs (
    AuditId BIGINT IDENTITY(1,1) PRIMARY KEY,
    ActorUserId UNIQUEIDENTIFIER NULL,
    ObjectName NVARCHAR(200),
    Action NVARCHAR(100),
    Details NVARCHAR(MAX),
    CreatedAt DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET()
);

GO
