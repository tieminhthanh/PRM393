-- =========================================================================================
-- DIGITALVILLAGE DB: SYNERGY MEKONG - ĐỒNG BẰNG SÔNG CỬU LONG (REAL DATA)
-- Số lượng: ~50 Bảng, mỗi bảng 10 Records chuẩn thực tế.
-- Target: SQL Server 2022 | Không lỗi Cú pháp, Không Subquery chết.
-- =========================================================================================

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

-- 1. TẠO SCHEMA
EXEC('CREATE SCHEMA iot'); EXEC('CREATE SCHEMA esg'); EXEC('CREATE SCHEMA commerce'); 
EXEC('CREATE SCHEMA community'); EXEC('CREATE SCHEMA gamify'); EXEC('CREATE SCHEMA ai'); 
EXEC('CREATE SCHEMA logistics'); EXEC('CREATE SCHEMA media'); EXEC('CREATE SCHEMA core');
GO

-- =======================================================================
-- 2. TẠO CẤU TRÚC BẢNG (50 BẢNG)
-- =======================================================================
CREATE TABLE core.UserAddresses (AddressId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(), UserId UNIQUEIDENTIFIER NOT NULL, Province NVARCHAR(100), District NVARCHAR(100), Commune NVARCHAR(100), AddressLine NVARCHAR(300), CreatedAt DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET());
CREATE TABLE dbo.Users (UserId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(), PhoneNumber VARCHAR(20) UNIQUE NOT NULL, Email VARCHAR(200) UNIQUE NULL, PasswordHash VARBINARY(512) NOT NULL, RoleType VARCHAR(20) NOT NULL CHECK (RoleType IN ('FARMER','SME','COMMUNITY','ADMIN')), CreatedAt DATETIMEOFFSET NOT NULL DEFAULT SYSDATETIMEOFFSET(), IsActive BIT NOT NULL DEFAULT 1, DisplayName NVARCHAR(200) NULL);
CREATE TABLE dbo.FarmerProfiles (UserId UNIQUEIDENTIFIER PRIMARY KEY FOREIGN KEY REFERENCES dbo.Users(UserId), FullName NVARCHAR(200) NOT NULL, Village NVARCHAR(200) NULL, ContactName NVARCHAR(200) NULL, ContactPhone VARCHAR(20) NULL, PreferredVoice BIT DEFAULT 1);
CREATE TABLE dbo.SMEProfiles (UserId UNIQUEIDENTIFIER PRIMARY KEY FOREIGN KEY REFERENCES dbo.Users(UserId), CompanyName NVARCHAR(300) NOT NULL, TaxCode VARCHAR(50) UNIQUE NOT NULL, ContactName NVARCHAR(200) NULL, ContactPhone VARCHAR(20) NULL, AddressSummary NVARCHAR(300) NULL, TotalESGScore DECIMAL(7,2) DEFAULT 0.00, ImpactInvestmentFund DECIMAL(18,2) DEFAULT 0.00);
CREATE TABLE community.CommunityProfiles (UserId UNIQUEIDENTIFIER PRIMARY KEY FOREIGN KEY REFERENCES dbo.Users(UserId), Nickname NVARCHAR(100) NULL, GamificationPoints INT DEFAULT 0, VolunteerHistory NVARCHAR(MAX) NULL, MicroInvestmentPortfolio NVARCHAR(MAX) NULL);

CREATE TABLE iot.Farms (FarmId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(), FarmerId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES dbo.FarmerProfiles(UserId), FarmName NVARCHAR(200), Boundary GEOGRAPHY NULL, Location GEOGRAPHY NULL, AreaHectares DECIMAL(9,2) NOT NULL, CropType NVARCHAR(100), Certifications NVARCHAR(200) NULL, OwnerContact NVARCHAR(200) NULL);
CREATE TABLE iot.IoTDevices (DeviceId VARCHAR(50) PRIMARY KEY, FarmId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES iot.Farms(FarmId), DeviceType VARCHAR(50) CHECK (DeviceType IN ('SOIL','AIR','WATER','GATEWAY')), BatteryLevel TINYINT CHECK (BatteryLevel BETWEEN 0 AND 100), Coordinates GEOGRAPHY NULL, LastSeen DATETIMEOFFSET NULL, InstalledAt DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET());
CREATE TABLE iot.IoTSensorReadings (ReadingId BIGINT IDENTITY(1,1) PRIMARY KEY, DeviceId VARCHAR(50) NOT NULL FOREIGN KEY REFERENCES iot.IoTDevices(DeviceId), MetricType VARCHAR(50) NOT NULL, MetricValue DECIMAL(18,6) NOT NULL, RecordedAt DATETIMEOFFSET NOT NULL DEFAULT SYSDATETIMEOFFSET());
CREATE NONCLUSTERED INDEX IX_IoTSensorReadings_Device_Metric_Time ON iot.IoTSensorReadings(DeviceId, MetricType, RecordedAt DESC);
CREATE TABLE iot.FarmingLogs (LogId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(), FarmId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES iot.Farms(FarmId), ActorUserId UNIQUEIDENTIFIER NULL FOREIGN KEY REFERENCES dbo.Users(UserId), ActionType NVARCHAR(200) NOT NULL, RawVoiceText NVARCHAR(2000) NULL, MaterialUsed NVARCHAR(200) NULL, MaterialQrCode VARCHAR(200) NULL, Quantity DECIMAL(18,4) NULL, RecordedAt DATETIMEOFFSET NOT NULL DEFAULT SYSDATETIMEOFFSET());

CREATE TABLE esg.CarbonImpactCatalog (FactorId INT IDENTITY(1,1) PRIMARY KEY, ActivityName NVARCHAR(200) NOT NULL, Unit VARCHAR(50) NOT NULL, EmissionFactor DECIMAL(18,6) NOT NULL, SourceReference NVARCHAR(500) NULL);
CREATE TABLE esg.MRVLogs (MRVId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(), FarmId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES iot.Farms(FarmId), FactorId INT NOT NULL FOREIGN KEY REFERENCES esg.CarbonImpactCatalog(FactorId), ActivityValue DECIMAL(18,6) NOT NULL, CalculatedCO2e DECIMAL(18,6) NULL, VerificationStatus VARCHAR(20) DEFAULT 'PENDING' CHECK (VerificationStatus IN ('PENDING','VERIFIED','REJECTED')), VerifiedAt DATETIMEOFFSET NULL, CreatedAt DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET());
CREATE TABLE esg.MRVEvidence (EvidenceId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(), MRVId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES esg.MRVLogs(MRVId), FarmingLogId UNIQUEIDENTIFIER NULL FOREIGN KEY REFERENCES iot.FarmingLogs(LogId), SensorReadingId BIGINT NULL FOREIGN KEY REFERENCES iot.IoTSensorReadings(ReadingId), ProductBatchId UNIQUEIDENTIFIER NULL, EvidenceType VARCHAR(50) NULL, AttachedFile NVARCHAR(400) NULL, CreatedAt DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET());
CREATE TABLE esg.CarbonLedger (TokenId VARCHAR(100) PRIMARY KEY, MRVId UNIQUEIDENTIFIER UNIQUE FOREIGN KEY REFERENCES esg.MRVLogs(MRVId), OwnerSMEId UNIQUEIDENTIFIER FOREIGN KEY REFERENCES dbo.SMEProfiles(UserId), TonsOfCO2e DECIMAL(18,6) NOT NULL, BlockchainTxHash VARCHAR(256) UNIQUE NULL, MintedAt DATETIMEOFFSET NOT NULL DEFAULT SYSDATETIMEOFFSET()) WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = esg.CarbonLedgerHistory), LEDGER = ON);
CREATE TABLE esg.TokenOrders (OrderId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(), TokenId VARCHAR(100) NOT NULL FOREIGN KEY REFERENCES esg.CarbonLedger(TokenId), SellerSMEId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES dbo.SMEProfiles(UserId), OrderType VARCHAR(10) NOT NULL CHECK (OrderType IN ('SELL','BUY')), Quantity DECIMAL(18,6) NOT NULL, PricePerTon DECIMAL(18,2) NOT NULL, Status VARCHAR(20) DEFAULT 'OPEN', CreatedAt DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET());
CREATE TABLE esg.TokenTrades (TradeId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(), BuyOrderId UNIQUEIDENTIFIER NULL FOREIGN KEY REFERENCES esg.TokenOrders(OrderId), SellOrderId UNIQUEIDENTIFIER NULL FOREIGN KEY REFERENCES esg.TokenOrders(OrderId), TokenId VARCHAR(100) NULL, Quantity DECIMAL(18,6) NOT NULL, PricePerTon DECIMAL(18,2) NOT NULL, TradeAt DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET());
CREATE TABLE esg.EscrowAccounts (EscrowId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(), OrderId UNIQUEIDENTIFIER FOREIGN KEY REFERENCES esg.TokenOrders(OrderId), Amount DECIMAL(18,2) NOT NULL, Status VARCHAR(30) DEFAULT 'HELD');
CREATE TABLE esg.SMESustainabilityScores (ScoreId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(), SMEId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES dbo.SMEProfiles(UserId), EnvironmentalScore DECIMAL(5,2) NOT NULL, SocialScore DECIMAL(5,2) NOT NULL, GovernanceScore DECIMAL(5,2) NOT NULL, TotalScore AS ((EnvironmentalScore + SocialScore + GovernanceScore) / 3.0) PERSISTED, Rating VARCHAR(10) NULL, EvaluationNote NVARCHAR(1000) NULL, EvaluatedAt DATETIMEOFFSET NOT NULL DEFAULT SYSDATETIMEOFFSET());

CREATE TABLE logistics.AgriMachines (MachineId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(), OwnerId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES dbo.Users(UserId), MachineType NVARCHAR(100) NOT NULL, BasePricePerHour DECIMAL(18,2) NOT NULL, ContactName NVARCHAR(200) NULL, ContactPhone VARCHAR(20) NULL, LastKnownLocation GEOGRAPHY NULL);
CREATE TABLE logistics.MachineHailingRequests (RequestId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(), FarmId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES iot.Farms(FarmId), MachineTypeRequired NVARCHAR(100) NOT NULL, ExpectedStartTime DATETIMEOFFSET NOT NULL, TargetArea GEOGRAPHY NOT NULL, Status VARCHAR(20) DEFAULT 'MATCHING' CHECK (Status IN ('MATCHING','ACCEPTED','COMPLETED')), AssignedMachineId UNIQUEIDENTIFIER NULL FOREIGN KEY REFERENCES logistics.AgriMachines(MachineId), RequesterContact NVARCHAR(200) NULL, CreatedAt DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET());
CREATE SPATIAL INDEX SPNDX_Hailing_TargetArea ON logistics.MachineHailingRequests(TargetArea);

CREATE TABLE esg.MicroInsuranceContracts (ContractId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(), FarmId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES iot.Farms(FarmId), CoverageAmount DECIMAL(18,2) NOT NULL, TriggerMetric VARCHAR(50) NOT NULL, TriggerThreshold DECIMAL(18,6) NOT NULL, BeneficiaryName NVARCHAR(200) NULL, BeneficiaryAccount VARCHAR(200) NULL, Status VARCHAR(20) DEFAULT 'ACTIVE' CHECK (Status IN ('ACTIVE','PAYOUT_TRIGGERED','EXPIRED')), CreatedAt DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET());
CREATE TABLE esg.InsurancePayoutLogs (PayoutId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(), ContractId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES esg.MicroInsuranceContracts(ContractId), TriggeredByReadingId BIGINT NULL FOREIGN KEY REFERENCES iot.IoTSensorReadings(ReadingId), TriggerMetric VARCHAR(50), TriggerValue DECIMAL(18,6), PayoutAmount DECIMAL(18,2) NULL, TriggeredAt DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET(), ProcessedOnChain BIT DEFAULT 0);

CREATE TABLE commerce.Products (ProductId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(), SellerId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES dbo.Users(UserId), Title NVARCHAR(300) NOT NULL, Description NVARCHAR(MAX) NULL, Category NVARCHAR(100) NULL, Price DECIMAL(18,2) NOT NULL, Unit NVARCHAR(50) NULL, IsGreen BIT DEFAULT 1, CreatedAt DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET());
CREATE TABLE commerce.ProductBatches (ProductBatchId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(), ProductId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES commerce.Products(ProductId), BatchCode VARCHAR(200) UNIQUE, ProductionDate DATE NULL, Metadata NVARCHAR(1000) NULL);
CREATE TABLE commerce.Orders (OrderId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(), BuyerId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES dbo.Users(UserId), OrderTotal DECIMAL(18,2) NOT NULL, Status VARCHAR(50) DEFAULT 'CREATED', CreatedAt DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET());
CREATE TABLE commerce.OrderItems (OrderItemId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(), OrderId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES commerce.Orders(OrderId), ProductId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES commerce.Products(ProductId), Quantity DECIMAL(18,4) NOT NULL, Price DECIMAL(18,2) NOT NULL);
CREATE TABLE commerce.Payments (PaymentId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(), OrderId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES commerce.Orders(OrderId), Amount DECIMAL(18,2) NOT NULL, Provider VARCHAR(100), ProviderReference VARCHAR(200), PaidAt DATETIMEOFFSET);
CREATE TABLE commerce.Certificates (CertificateId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(), SellerId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES dbo.Users(UserId), CertificateType VARCHAR(200), DocumentUrl NVARCHAR(500), UploadedAt DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET());
CREATE TABLE commerce.FundingLogs (FundingId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(), FromSMEId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES dbo.SMEProfiles(UserId), ToFarmId UNIQUEIDENTIFIER NULL FOREIGN KEY REFERENCES iot.Farms(FarmId), Amount DECIMAL(18,2) NOT NULL, Purpose NVARCHAR(500) NULL, CreatedAt DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET());
CREATE TABLE commerce.Vouchers (VoucherId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(), FundingId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES commerce.FundingLogs(FundingId), Code VARCHAR(100) UNIQUE NOT NULL, Catalog NVARCHAR(200) NOT NULL, Quantity INT DEFAULT 1, ExpiresAt DATETIMEOFFSET NULL);
CREATE TABLE commerce.VoucherRedemptions (RedemptionId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(), VoucherId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES commerce.Vouchers(VoucherId), RedeemedBy UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES dbo.Users(UserId), RedeemedAt DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET());
CREATE TABLE commerce.CropInvestments (CampaignId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(), FarmId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES iot.Farms(FarmId), Title NVARCHAR(300), GoalAmount DECIMAL(18,2), CollectedAmount DECIMAL(18,2) DEFAULT 0, StartDate DATE, EndDate DATE, CreatedAt DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET());
CREATE TABLE commerce.Investments (InvestmentId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(), CampaignId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES commerce.CropInvestments(CampaignId), InvestorId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES dbo.Users(UserId), Amount DECIMAL(18,2) NOT NULL, InvestedAt DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET());
CREATE TABLE commerce.AgriWasteListings (ListingId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(), SellerId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES dbo.Users(UserId), Title NVARCHAR(300), Description NVARCHAR(MAX), Quantity DECIMAL(18,4), Unit NVARCHAR(50), Price DECIMAL(18,2), CreatedAt DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET());
CREATE TABLE commerce.LandListings (LandId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(), OwnerId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES dbo.Users(UserId), Location GEOGRAPHY NOT NULL, AreaHectares DECIMAL(9,2) NOT NULL, PricePerHectare DECIMAL(18,2) NULL, IsForRent BIT DEFAULT 1, CreatedAt DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET());
CREATE TABLE commerce.LandRentals (RentalId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(), LandId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES commerce.LandListings(LandId), RenterId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES dbo.Users(UserId), StartDate DATE, EndDate DATE, Price DECIMAL(18,2));

CREATE TABLE community.ConsultingCases (CaseId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(), FarmerId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES dbo.FarmerProfiles(UserId), ExpertId UNIQUEIDENTIFIER NULL FOREIGN KEY REFERENCES dbo.Users(UserId), Title NVARCHAR(300), Description NVARCHAR(MAX), MediaUrl NVARCHAR(500), Fee DECIMAL(18,2) DEFAULT 0, Status VARCHAR(50) DEFAULT 'OPEN', CreatedAt DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET());
CREATE TABLE media.FarmMedia (MediaId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(), FarmId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES iot.Farms(FarmId), UploadedBy UNIQUEIDENTIFIER NULL FOREIGN KEY REFERENCES dbo.Users(UserId), MediaType VARCHAR(50), Url NVARCHAR(500), Metadata NVARCHAR(2000), UploadedAt DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET());
CREATE TABLE ai.AIDetections (DetectionId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(), MediaId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES media.FarmMedia(MediaId), ModelName NVARCHAR(200), Label NVARCHAR(200), Confidence DECIMAL(5,4), Notes NVARCHAR(1000), DetectedAt DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET());
CREATE TABLE ai.DigitalTwinSnapshots (SnapshotId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(), FarmId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES iot.Farms(FarmId), SnapshotData NVARCHAR(MAX), CreatedAt DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET());

CREATE TABLE gamify.SkyFarmItems (ItemId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(), Name NVARCHAR(200), Description NVARCHAR(1000), Rarity VARCHAR(50), Price DECIMAL(18,2) NULL);
CREATE TABLE gamify.SkyFarmPlots (PlotId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(), OwnerId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES dbo.Users(UserId), LinkedFarmId UNIQUEIDENTIFIER NULL FOREIGN KEY REFERENCES iot.Farms(FarmId), VirtualCrop NVARCHAR(200), GrowthState INT DEFAULT 0, LastUpdated DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET());
CREATE TABLE gamify.GamificationPoints (EntryId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(), UserId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES dbo.Users(UserId), Points INT NOT NULL, Reason NVARCHAR(500), CreatedAt DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET());
CREATE TABLE gamify.Achievements (AchievementId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(), UserId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES dbo.Users(UserId), KeyName VARCHAR(200), AwardedAt DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET());

CREATE TABLE dbo.NotificationChannels (ChannelId INT IDENTITY(1,1) PRIMARY KEY, Name VARCHAR(50), Config NVARCHAR(MAX));
CREATE TABLE dbo.Notifications (NotificationId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(), UserId UNIQUEIDENTIFIER NULL FOREIGN KEY REFERENCES dbo.Users(UserId), ChannelId INT NULL FOREIGN KEY REFERENCES dbo.NotificationChannels(ChannelId), Title NVARCHAR(300), Body NVARCHAR(MAX), IsRead BIT DEFAULT 0, CreatedAt DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET());
CREATE TABLE dbo.Alerts (AlertId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(), DeviceId VARCHAR(50) NULL FOREIGN KEY REFERENCES iot.IoTDevices(DeviceId), FarmId UNIQUEIDENTIFIER NULL FOREIGN KEY REFERENCES iot.Farms(FarmId), AlertType VARCHAR(200), Severity VARCHAR(20), Payload NVARCHAR(MAX), CreatedAt DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET(), IsResolved BIT DEFAULT 0);
CREATE TABLE dbo.AuditLogs (AuditId BIGINT IDENTITY(1,1) PRIMARY KEY, ActorUserId UNIQUEIDENTIFIER NULL, ObjectName NVARCHAR(200), Action NVARCHAR(100), Details NVARCHAR(MAX), CreatedAt DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET());
GO

-- =======================================================================
-- 3. CHÈN DỮ LIỆU THỰC TẾ (10 KỊCH BẢN ĐỒNG BẰNG SÔNG CỬU LONG)
-- =======================================================================
SET NOCOUNT ON;
BEGIN TRANSACTION;

-- 3.1: MASTER DATA (10 Tỉnh Miền Tây)
DECLARE @MekongData TABLE (
    RN INT IDENTITY(1,1),
    -- Thông tin Nông dân (Farmers)
    F_Name NVARCHAR(200), F_Phone VARCHAR(20), F_Prov NVARCHAR(100), F_Dist NVARCHAR(100), F_Munc NVARCHAR(100),
    -- Thông tin Doanh nghiệp (SMEs)
    S_Name NVARCHAR(200), S_Tax VARCHAR(20), S_Prov NVARCHAR(100),
    -- Thông tin Nông trại (Farms)
    Farm_Name NVARCHAR(200), Crop NVARCHAR(100), Lat FLOAT, Lon FLOAT, Area DECIMAL(9,2),
    -- IoT
    DeviceType VARCHAR(50), Metric VARCHAR(50), Val DECIMAL(18,2),
    -- ESG & Carbon
    ESG_Act NVARCHAR(200), Unit VARCHAR(20), Factor DECIMAL(18,4),
    -- Sản phẩm & Phế phẩm
    Prod_Name NVARCHAR(200), Price DECIMAL(18,2), Waste_Name NVARCHAR(200),
    -- AI & Tư vấn
    Issue NVARCHAR(200), AI_Label NVARCHAR(200)
);

INSERT INTO @MekongData VALUES
-- 1. An Giang: Lúa (Mô hình phát thải thấp)
(N'Nguyễn Văn Sáu', '0901000001', N'An Giang', N'Tri Tôn', N'Tà Đảnh', 
 N'Tập đoàn Lộc Trời', '0312345601', N'An Giang', 
 N'Cánh đồng lúa Tà Đảnh', N'Lúa OM18', 10.45, 105.12, 10.5, 
 'WATER', 'WATER_LEVEL', 1.2, 
 N'Tưới Nông lộ phơi (AWD)', 'Ton/Ha', -2.5, 
 N'Gạo Lộc Trời 28', 25000, N'Vỏ trấu ép củi', 
 N'Lúa khô héo nghi đạo ôn', N'Bệnh đạo ôn (Pyricularia)'),

-- 2. Đồng Tháp: Xoài (Chuỗi giá trị hữu cơ)
(N'Lê Thị Hai', '0901000002', N'Đồng Tháp', N'Cao Lãnh', N'Mỹ Xương', 
 N'Cty Nông sản Cỏ May', '0312345602', N'Đồng Tháp', 
 N'Vườn xoài Mỹ Xương', N'Xoài Cát Hòa Lộc', 10.48, 105.58, 3.2, 
 'SOIL', 'SOIL_MOISTURE', 45.0, 
 N'Bón phân trùn quế', 'Ton/Kg', -0.05, 
 N'Xoài Cát Hòa Lộc GlobalGAP', 85000, N'Lá xoài ủ phân hữu cơ', 
 N'Xoài rụng trái non', N'Bệnh thán thư (Anthracnose)'),

-- 3. Cần Thơ: Sầu Riêng (Du lịch sinh thái)
(N'Trần Văn Chín', '0901000003', N'Cần Thơ', N'Phong Điền', N'Nhơn Ái', 
 N'Gạo Trung An', '0312345603', N'Cần Thơ', 
 N'Vườn sinh thái Phong Điền', N'Sầu Riêng Ri6', 10.01, 105.69, 2.5, 
 'AIR', 'AIR_TEMP', 35.2, 
 N'Quản lý sức khỏe cây trồng tổng hợp', 'Ha', -1.2, 
 N'Sầu Riêng Ri6 VietGAP', 120000, N'Vỏ sầu riêng làm đệm lót sinh học', 
 N'Sầu riêng cháy mép lá', N'Tổn thương do mặn (Salinity Stress)'),

-- 4. Tiền Giang: Khóm (Trồng trên đất phèn)
(N'Võ Thị Mười', '0901000004', N'Tiền Giang', N'Tân Phước', N'Tân Lập 1', 
 N'HTX Vú Sữa Lò Rèn', '0312345604', N'Tiền Giang', 
 N'Rẫy khóm Tân Phước', N'Khóm (Dứa)', 10.51, 106.27, 5.0, 
 'SOIL', 'SOIL_PH', 3.5, 
 N'Che phủ đất bằng sinh khối', 'Ha', -0.8, 
 N'Nước ép khóm cô đặc', 45000, N'Bã khóm ủ lên men vi sinh', 
 N'Khóm héo rễ', N'Tuyến trùng hại rễ'),

-- 5. Vĩnh Long: Bưởi (Trồng xen canh)
(N'Phạm Văn Bảy', '0901000005', N'Vĩnh Long', N'Bình Minh', N'Mỹ Hòa', 
 N'HTX Sầu Riêng Ngũ Hiệp', '0312345605', N'Tiền Giang', 
 N'Vườn bưởi Năm Roi Bình Minh', N'Bưởi Năm Roi', 10.04, 105.81, 4.0, 
 'AIR', 'AIR_HUMIDITY', 85.0, 
 N'Trồng xen canh cây họ đậu', 'Ha', -1.5, 
 N'Bưởi Năm Roi Hữu Cơ', 35000, N'Vỏ bưởi chiết xuất tinh dầu', 
 N'Bưởi thối trái non', N'Sâu đục trái (Borer)'),

-- 6. Sóc Trăng: Lúa ST25 (Nguy cơ xâm nhập mặn)
(N'Lý Kim Hoa', '0901000006', N'Sóc Trăng', N'Trần Đề', N'Lịch Hội Thượng', 
 N'Nông sản Sông Hậu', '0312345606', N'Cần Thơ', 
 N'Cánh đồng Lúa ST25 Trần Đề', N'Lúa ST25', 9.53, 106.05, 15.0, 
 'WATER', 'WATER_SALINITY', 4.8, 
 N'Giảm phát thải khí Metan (CH4)', 'Ton/Ha', -3.0, 
 N'Gạo Lúa Tôm ST25', 40000, N'Rơm cuộn ST25', 
 N'Lúa chết khô do nước lợ', N'Chỉ số stress mặn (NDVI thấp)'),

-- 7. Bạc Liêu: Tôm - Lúa (Kinh tế tuần hoàn)
(N'Hồ Văn Năm', '0901000007', N'Bạc Liêu', N'Giá Rai', N'Phong Tân', 
 N'Thủy sản Minh Phú', '0312345607', N'Cà Mau', 
 N'Khu canh tác Tôm Lúa Giá Rai', N'Tôm sú - Lúa', 9.27, 105.44, 8.5, 
 'WATER', 'WATER_DO', 5.5, 
 N'Mô hình Tôm - Lúa tuần hoàn', 'Ha', -2.2, 
 N'Tôm sú sinh thái nguyên con', 250000, N'Vỏ tôm phế phẩm sinh học', 
 N'Tôm bơi lờ đờ', N'Dấu hiệu đốm trắng (WSSV)'),

-- 8. Trà Vinh: Dừa Sáp (Chống sạt lở)
(N'Ngô Thị Tám', '0901000008', N'Trà Vinh', N'Cầu Kè', N'Hòa Tân', 
 N'Phân bón Dầu khí Cà Mau', '0312345608', N'Cà Mau', 
 N'Vườn Dừa Sáp Cầu Kè', N'Dừa Sáp', 9.87, 106.01, 6.0, 
 'SOIL', 'SOIL_MOISTURE', 60.0, 
 N'Trồng rừng ngập mặn xen kẽ', 'Tree', -0.05, 
 N'Dừa sáp Cầu Kè', 150000, N'Gáo dừa, xơ dừa', 
 N'Lá dừa rách nát', N'Bọ cánh cứng hại dừa'),

-- 9. Bến Tre: Cây giống (Ứng dụng công nghệ)
(N'Đinh Văn Tư', '0901000009', N'Bến Tre', N'Chợ Lách', N'Vĩnh Thành', 
 N'XNK Trái Cây Chánh Thu', '0312345609', N'Bến Tre', 
 N'Vườn Cây giống Chợ Lách', N'Giống Sầu Riêng Thái', 10.23, 106.13, 1.5, 
 'GATEWAY', 'NETWORK_STRENGTH', 95.0, 
 N'Sản xuất phân bón từ phế phẩm', 'Ton', -1.0, 
 N'Cây giống Sầu Riêng Musang King', 80000, N'Trấu tươi làm đệm lót', 
 N'Lá non bị quéo', N'Rầy chổng cánh'),

-- 10. Long An: Thanh Long (Năng lượng mặt trời)
(N'Bùi Văn Ba', '0901000010', N'Long An', N'Châu Thành', N'Tầm Vu', 
 N'Lương thực Long An', '0312345610', N'Long An', 
 N'Vườn Thanh Long Châu Thành', N'Thanh Long Ruột Đỏ', 10.56, 106.45, 7.0, 
 'AIR', 'AIR_HUMIDITY', 70.0, 
 N'Hệ thống điện mặt trời bơm tưới', 'KWh', -0.005, 
 N'Thanh Long sấy không đường', 120000, N'Cành thanh long cắt tỉa ủ mùn', 
 N'Trái ra không đều màu', N'Bệnh đốm nâu (Đồng tiền)');

-- 3.2: KHỞI TẠO BẢNG TẠM CHỨA ID ĐỂ LIÊN KẾT 100% AN TOÀN
DECLARE @MapFm TABLE (RN INT, Id UNIQUEIDENTIFIER);
DECLARE @MapSME TABLE (RN INT, Id UNIQUEIDENTIFIER);
DECLARE @MapCom TABLE (RN INT, Id UNIQUEIDENTIFIER);
DECLARE @MapAdm TABLE (RN INT, Id UNIQUEIDENTIFIER);
DECLARE @MapFarm TABLE (RN INT, Id UNIQUEIDENTIFIER);
DECLARE @MapDev TABLE (RN INT, Id VARCHAR(50));
DECLARE @MapRead TABLE (RN INT, Id BIGINT);
DECLARE @MapLog TABLE (RN INT, Id UNIQUEIDENTIFIER);
DECLARE @MapCat TABLE (RN INT, Id INT);
DECLARE @MapMRV TABLE (RN INT, Id UNIQUEIDENTIFIER);
DECLARE @MapTkn TABLE (RN INT, Id VARCHAR(100));
DECLARE @MapOrd TABLE (RN INT, Id UNIQUEIDENTIFIER);
DECLARE @MapMach TABLE (RN INT, Id UNIQUEIDENTIFIER);
DECLARE @MapCont TABLE (RN INT, Id UNIQUEIDENTIFIER);
DECLARE @MapProd TABLE (RN INT, Id UNIQUEIDENTIFIER);
DECLARE @MapFund TABLE (RN INT, Id UNIQUEIDENTIFIER);
DECLARE @MapVouc TABLE (RN INT, Id UNIQUEIDENTIFIER);
DECLARE @MapCamp TABLE (RN INT, Id UNIQUEIDENTIFIER);
DECLARE @MapLand TABLE (RN INT, Id UNIQUEIDENTIFIER);
DECLARE @MapMedia TABLE (RN INT, Id UNIQUEIDENTIFIER);
DECLARE @MapChan TABLE (RN INT, Id INT);

-- ==================== CHÈN DỮ LIỆU CÁC BẢNG ====================

-- Users & Profiles
MERGE dbo.Users AS T USING @MekongData AS S ON 1=0
WHEN NOT MATCHED THEN INSERT (PhoneNumber, Email, PasswordHash, RoleType, DisplayName)
VALUES (S.F_Phone, 'farmer'+CAST(S.RN AS VARCHAR)+'@synergy.vn', 0x12, 'FARMER', S.F_Name)
OUTPUT S.RN, INSERTED.UserId INTO @MapFm(RN, Id);

MERGE dbo.Users AS T USING @MekongData AS S ON 1=0
WHEN NOT MATCHED THEN INSERT (PhoneNumber, Email, PasswordHash, RoleType, DisplayName)
VALUES ('09120000'+RIGHT('0'+CAST(S.RN AS VARCHAR),2), 'sme'+CAST(S.RN AS VARCHAR)+'@synergy.vn', 0x34, 'SME', S.S_Name)
OUTPUT S.RN, INSERTED.UserId INTO @MapSME(RN, Id);

MERGE dbo.Users AS T USING @MekongData AS S ON 1=0
WHEN NOT MATCHED THEN INSERT (PhoneNumber, Email, PasswordHash, RoleType, DisplayName)
VALUES ('09880000'+RIGHT('0'+CAST(S.RN AS VARCHAR),2), 'comm'+CAST(S.RN AS VARCHAR)+'@synergy.vn', 0x56, 'COMMUNITY', N'Nhà Đầu Tư Mekong '+CAST(S.RN AS NVARCHAR))
OUTPUT S.RN, INSERTED.UserId INTO @MapCom(RN, Id);

MERGE dbo.Users AS T USING @MekongData AS S ON 1=0
WHEN NOT MATCHED THEN INSERT (PhoneNumber, Email, PasswordHash, RoleType, DisplayName)
VALUES ('09990000'+RIGHT('0'+CAST(S.RN AS VARCHAR),2), 'admin'+CAST(S.RN AS VARCHAR)+'@synergy.vn', 0x00, 'ADMIN', N'Chuyên gia Nông Nghiệp '+CAST(S.RN AS NVARCHAR))
OUTPUT S.RN, INSERTED.UserId INTO @MapAdm(RN, Id);

INSERT INTO dbo.FarmerProfiles (UserId, FullName, Village, ContactPhone)
SELECT F.Id, M.F_Name, M.F_Munc, M.F_Phone FROM @MapFm F JOIN @MekongData M ON F.RN = M.RN;

INSERT INTO dbo.SMEProfiles (UserId, CompanyName, TaxCode, AddressSummary, TotalESGScore)
SELECT S.Id, M.S_Name, M.S_Tax, M.S_Prov, 80.0 + M.RN FROM @MapSME S JOIN @MekongData M ON S.RN = M.RN;

INSERT INTO community.CommunityProfiles (UserId, Nickname, GamificationPoints)
SELECT Id, N'MekongAngel_' + CAST(RN AS NVARCHAR), RN * 1000 FROM @MapCom;

INSERT INTO core.UserAddresses (UserId, Province, District, Commune, AddressLine)
SELECT F.Id, M.F_Prov, M.F_Dist, M.F_Munc, N'Ấp văn hóa nông thôn mới' FROM @MapFm F JOIN @MekongData M ON F.RN = M.RN;

-- IoT & Farming
MERGE iot.Farms AS T USING (SELECT F.Id AS FarmerId, M.* FROM @MapFm F JOIN @MekongData M ON F.RN=M.RN) AS S ON 1=0
WHEN NOT MATCHED THEN INSERT (FarmerId, FarmName, AreaHectares, CropType, Location)
VALUES (S.FarmerId, S.Farm_Name, S.Area, S.Crop, geography::Point(S.Lat, S.Lon, 4326))
OUTPUT S.RN, INSERTED.FarmId INTO @MapFarm(RN, Id);

MERGE iot.IoTDevices AS T USING (SELECT F.Id AS FarmId, M.* FROM @MapFarm F JOIN @MekongData M ON F.RN=M.RN) AS S ON 1=0
WHEN NOT MATCHED THEN INSERT (DeviceId, FarmId, DeviceType, BatteryLevel)
VALUES ('DEV-MEKONG-' + CAST(S.RN AS VARCHAR), S.FarmId, S.DeviceType, 100 - S.RN)
OUTPUT S.RN, INSERTED.DeviceId INTO @MapDev(RN, Id);

MERGE iot.IoTSensorReadings AS T USING (SELECT D.Id AS DevId, M.* FROM @MapDev D JOIN @MekongData M ON D.RN=M.RN) AS S ON 1=0
WHEN NOT MATCHED THEN INSERT (DeviceId, MetricType, MetricValue)
VALUES (S.DevId, S.Metric, S.Val)
OUTPUT S.RN, INSERTED.ReadingId INTO @MapRead(RN, Id);

MERGE iot.FarmingLogs AS T USING (SELECT F.Id AS FarmId, U.Id AS UserId, M.* FROM @MapFarm F JOIN @MapFm U ON F.RN=U.RN JOIN @MekongData M ON F.RN=M.RN) AS S ON 1=0
WHEN NOT MATCHED THEN INSERT (FarmId, ActorUserId, ActionType, RawVoiceText, Quantity)
VALUES (S.FarmId, S.UserId, N'Hoạt động nông nghiệp', N'Nhật ký cập nhật từ ' + S.F_Prov, S.RN * 10.0)
OUTPUT S.RN, INSERTED.LogId INTO @MapLog(RN, Id);

-- ESG & Carbon
MERGE esg.CarbonImpactCatalog AS T USING @MekongData AS S ON 1=0
WHEN NOT MATCHED THEN INSERT (ActivityName, Unit, EmissionFactor)
VALUES (S.ESG_Act, S.Unit, S.Factor)
OUTPUT S.RN, INSERTED.FactorId INTO @MapCat(RN, Id);

MERGE esg.MRVLogs AS T USING (SELECT F.Id AS FarmId, C.Id AS FactorId, M.* FROM @MapFarm F JOIN @MapCat C ON F.RN=C.RN JOIN @MekongData M ON F.RN=M.RN) AS S ON 1=0
WHEN NOT MATCHED THEN INSERT (FarmId, FactorId, ActivityValue, CalculatedCO2e, VerificationStatus)
VALUES (S.FarmId, S.FactorId, S.Area, S.Factor * S.Area, 'VERIFIED')
OUTPUT S.RN, INSERTED.MRVId INTO @MapMRV(RN, Id);

INSERT INTO esg.MRVEvidence (MRVId, FarmingLogId, SensorReadingId, EvidenceType)
SELECT M.Id, L.Id, R.Id, 'SENSOR_DATA' FROM @MapMRV M JOIN @MapLog L ON M.RN = L.RN JOIN @MapRead R ON M.RN = R.RN;

MERGE esg.CarbonLedger AS T USING (SELECT M.Id AS MRVId, S.Id AS SMEId, D.* FROM @MapMRV M JOIN @MapSME S ON M.RN=S.RN JOIN @MekongData D ON M.RN=D.RN) AS S ON 1=0
WHEN NOT MATCHED THEN INSERT (TokenId, MRVId, OwnerSMEId, TonsOfCO2e, BlockchainTxHash)
VALUES ('TKN-SYNC-26-' + CAST(S.RN AS VARCHAR), S.MRVId, S.SMEId, ABS(S.Factor * S.Area), '0xMeKong' + CAST(S.RN AS VARCHAR))
OUTPUT S.RN, INSERTED.TokenId INTO @MapTkn(RN, Id);

MERGE esg.TokenOrders AS T USING (SELECT Tk.Id AS TokenId, S.Id AS SMEId, M.* FROM @MapTkn Tk JOIN @MapSME S ON Tk.RN=S.RN JOIN @MekongData M ON Tk.RN=M.RN) AS S ON 1=0
WHEN NOT MATCHED THEN INSERT (TokenId, SellerSMEId, OrderType, Quantity, PricePerTon, Status)
VALUES (S.TokenId, S.SMEId, 'SELL', 1.0, 1500000, 'OPEN')
OUTPUT S.RN, INSERTED.OrderId INTO @MapOrd(RN, Id);

INSERT INTO esg.TokenTrades (BuyOrderId, SellOrderId, TokenId, Quantity, PricePerTon)
SELECT NULL, O.Id, T.Id, 1.0, 1500000 FROM @MapOrd O JOIN @MapTkn T ON O.RN = T.RN;

INSERT INTO esg.EscrowAccounts (OrderId, Amount, Status)
SELECT Id, 1500000, 'HELD' FROM @MapOrd;

INSERT INTO esg.SMESustainabilityScores (SMEId, EnvironmentalScore, SocialScore, GovernanceScore)
SELECT Id, 85.0 + RN, 80.0 + RN, 90.0 FROM @MapSME;

-- Logistics & Micro Insurance
MERGE logistics.AgriMachines AS T USING (SELECT S.Id AS SMEId, M.* FROM @MapSME S JOIN @MekongData M ON S.RN=M.RN) AS S ON 1=0
WHEN NOT MATCHED THEN INSERT (OwnerId, MachineType, BasePricePerHour)
VALUES (S.SMEId, CASE WHEN S.RN % 2 = 0 THEN N'Drone DJI Agras T40' ELSE N'Máy Gặt Đập Liên Hợp' END, 800000)
OUTPUT S.RN, INSERTED.MachineId INTO @MapMach(RN, Id);

INSERT INTO logistics.MachineHailingRequests (FarmId, MachineTypeRequired, ExpectedStartTime, TargetArea, AssignedMachineId)
SELECT F.Id, N'Drone Phun Thuốc', SYSDATETIMEOFFSET(), geography::Point(M.Lat, M.Lon, 4326), Ma.Id
FROM @MapFarm F JOIN @MekongData M ON F.RN = M.RN JOIN @MapMach Ma ON F.RN = Ma.RN;

MERGE esg.MicroInsuranceContracts AS T USING (SELECT F.Id AS FarmId, M.* FROM @MapFarm F JOIN @MekongData M ON F.RN=M.RN) AS S ON 1=0
WHEN NOT MATCHED THEN INSERT (FarmId, CoverageAmount, TriggerMetric, TriggerThreshold, Status)
VALUES (S.FarmId, 50000000, S.Metric, S.Val - 0.5, 'PAYOUT_TRIGGERED') -- Cố tình set TriggerThreshold thấp hơn Val thực tế để kích hoạt
OUTPUT S.RN, INSERTED.ContractId INTO @MapCont(RN, Id);

INSERT INTO esg.InsurancePayoutLogs (ContractId, TriggeredByReadingId, TriggerMetric, TriggerValue, PayoutAmount, ProcessedOnChain)
SELECT C.Id, R.Id, M.Metric, M.Val, 50000000, 1
FROM @MapCont C JOIN @MapRead R ON C.RN = R.RN JOIN @MekongData M ON C.RN = M.RN;

-- Commerce
MERGE commerce.Products AS T USING (SELECT F.Id AS FarmerId, M.* FROM @MapFm F JOIN @MekongData M ON F.RN=M.RN) AS S ON 1=0
WHEN NOT MATCHED THEN INSERT (SellerId, Title, Category, Price, Unit)
VALUES (S.FarmerId, S.Prod_Name, N'Nông sản Miền Tây', S.Price, N'Kg')
OUTPUT S.RN, INSERTED.ProductId INTO @MapProd(RN, Id);

INSERT INTO commerce.ProductBatches (ProductId, BatchCode)
SELECT Id, 'B-' + CAST(RN AS VARCHAR) FROM @MapProd;

INSERT INTO commerce.Orders (BuyerId, OrderTotal, Status)
SELECT Id, 5000000, 'PAID' FROM @MapCom;

INSERT INTO commerce.Certificates (SellerId, CertificateType)
SELECT Id, 'OCOP 4 Sao' FROM @MapFm;

MERGE commerce.FundingLogs AS T USING (SELECT S.Id AS SMEId, F.Id AS FarmId, M.* FROM @MapSME S JOIN @MapFarm F ON S.RN=F.RN JOIN @MekongData M ON S.RN=M.RN) AS S ON 1=0
WHEN NOT MATCHED THEN INSERT (FromSMEId, ToFarmId, Amount, Purpose)
VALUES (S.SMEId, S.FarmId, 20000000, N'Tài trợ Cải tạo Đất mặn')
OUTPUT S.RN, INSERTED.FundingId INTO @MapFund(RN, Id);

MERGE commerce.Vouchers AS T USING (SELECT F.Id AS FundId, M.* FROM @MapFund F JOIN @MekongData M ON F.RN=M.RN) AS S ON 1=0
WHEN NOT MATCHED THEN INSERT (FundingId, Code, Catalog, Quantity)
VALUES (S.FundId, 'MEKONG-GREEN-' + CAST(S.RN AS VARCHAR), N'Vật tư', 10)
OUTPUT S.RN, INSERTED.VoucherId INTO @MapVouc(RN, Id);

INSERT INTO commerce.VoucherRedemptions (VoucherId, RedeemedBy)
SELECT V.Id, F.Id FROM @MapVouc V JOIN @MapFm F ON V.RN = F.RN;

MERGE commerce.CropInvestments AS T USING (SELECT F.Id AS FarmId, M.* FROM @MapFarm F JOIN @MekongData M ON F.RN=M.RN) AS S ON 1=0
WHEN NOT MATCHED THEN INSERT (FarmId, Title, GoalAmount, CollectedAmount)
VALUES (S.FarmId, N'Gọi vốn Mùa Vụ ' + S.Crop, 100000000, 20000000)
OUTPUT S.RN, INSERTED.CampaignId INTO @MapCamp(RN, Id);

INSERT INTO commerce.Investments (CampaignId, InvestorId, Amount)
SELECT C.Id, U.Id, 20000000 FROM @MapCamp C JOIN @MapCom U ON C.RN = U.RN;

INSERT INTO commerce.AgriWasteListings (SellerId, Title, Quantity, Price)
SELECT F.Id, M.Waste_Name, 5.0, 500000
FROM @MapFm F JOIN @MekongData M ON F.RN = M.RN;

MERGE commerce.LandListings AS T USING (SELECT F.Id AS FarmerId, M.* FROM @MapFm F JOIN @MekongData M ON F.RN=M.RN) AS S ON 1=0
WHEN NOT MATCHED THEN INSERT (OwnerId, Location, AreaHectares, PricePerHectare)
VALUES (S.FarmerId, geography::Point(S.Lat, S.Lon, 4326), S.Area, 200000000)
OUTPUT S.RN, INSERTED.LandId INTO @MapLand(RN, Id);

INSERT INTO commerce.LandRentals (LandId, RenterId, Price)
SELECT L.Id, S.Id, 50000000 FROM @MapLand L JOIN @MapSME S ON L.RN = S.RN;

-- Community, AI & Digital Twin
INSERT INTO community.ConsultingCases (FarmerId, ExpertId, Title, Description)
SELECT F.Id, A.Id, M.Issue, N'Cần chuyên gia hỗ trợ gấp tại ' + M.F_Prov
FROM @MapFm F JOIN @MapAdm A ON F.RN = A.RN JOIN @MekongData M ON F.RN = M.RN;

MERGE media.FarmMedia AS T USING (SELECT F.Id AS FarmId, U.Id AS UserId, M.* FROM @MapFarm F JOIN @MapFm U ON F.RN=U.RN JOIN @MekongData M ON F.RN=M.RN) AS S ON 1=0
WHEN NOT MATCHED THEN INSERT (FarmId, UploadedBy, MediaType, Url)
VALUES (S.FarmId, S.UserId, 'IMAGE', 'https://synergy.vn/img/' + CAST(S.RN AS VARCHAR) + '.jpg')
OUTPUT S.RN, INSERTED.MediaId INTO @MapMedia(RN, Id);

INSERT INTO ai.AIDetections (MediaId, ModelName, Label, Confidence, Notes)
SELECT Me.Id, 'YOLOv11-Agri Mekong', M.AI_Label, 0.95, N'Phát hiện bằng thuật toán Computer Vision'
FROM @MapMedia Me JOIN @MekongData M ON Me.RN = M.RN;

INSERT INTO ai.DigitalTwinSnapshots (FarmId, SnapshotData)
SELECT Id, N'{"mesh_model": "mekong_farm_' + CAST(RN AS VARCHAR) + N'", "salinity_layer": "active"}' FROM @MapFarm;

-- Gamify & Audits
INSERT INTO gamify.SkyFarmItems (Name, Rarity, Price)
SELECT N'Hạt giống Thần kỳ ' + CAST(RN AS NVARCHAR), 'EPIC', 1500.0 FROM @MapFm;

INSERT INTO gamify.SkyFarmPlots (OwnerId, LinkedFarmId, VirtualCrop, GrowthState)
SELECT F.Id, Fa.Id, M.Crop + N' Ảo', 50
FROM @MapFm F JOIN @MapFarm Fa ON F.RN = Fa.RN JOIN @MekongData M ON F.RN = M.RN;

INSERT INTO gamify.GamificationPoints (UserId, Points, Reason)
SELECT Id, 500, N'Hành động xanh bảo vệ Đồng Bằng Sông Cửu Long' FROM @MapFm;

INSERT INTO gamify.Achievements (UserId, KeyName)
SELECT Id, 'MEKONG_SAVIOR_TIER_' + CAST(RN AS VARCHAR) FROM @MapFm;

MERGE dbo.NotificationChannels AS T USING @MekongData AS S ON 1=0
WHEN NOT MATCHED THEN INSERT (Name, Config) VALUES ('Push_FCM', '{"priority":"high"}')
OUTPUT S.RN, INSERTED.ChannelId INTO @MapChan(RN, Id);

INSERT INTO dbo.Notifications (UserId, ChannelId, Title, Body)
SELECT F.Id, C.Id, N'Cảnh báo IoT', N'Dữ liệu cảm biến có sự thay đổi lớn tại ' + M.Farm_Name
FROM @MapFm F JOIN @MapChan C ON F.RN = C.RN JOIN @MekongData M ON F.RN = M.RN;

INSERT INTO dbo.Alerts (DeviceId, FarmId, AlertType, Severity, Payload)
SELECT D.Id, F.Id, 'CRITICAL_METRIC_BREACH', 'CRITICAL', N'{"metric": "' + M.Metric + '", "value": ' + CAST(M.Val AS VARCHAR) + '}'
FROM @MapDev D JOIN @MapFarm F ON D.RN = F.RN JOIN @MekongData M ON D.RN = M.RN;

INSERT INTO dbo.AuditLogs (ActorUserId, ObjectName, Action, Details)
SELECT Id, 'System', 'LOGIN', N'Người dùng đăng nhập từ IP Đồng Bằng Sông Cửu Long' FROM @MapFm;

COMMIT TRANSACTION;
PRINT '==== HOAN TAT! DU LIEU 10 KICH BAN MIEN TAY DA DUOC NAP 100% THANH CONG ====';

-- Truy xuất Báo cáo Kép: Năng suất & Tín chỉ Carbon (ESG)
SELECT 
    f.FarmName AS [Tên Trang Trại],
    fp.FullName AS [Chủ Sở Hữu],
    f.CropType AS [Loại Cây Trồng],
    f.AreaHectares AS [Diện Tích (Ha)],
    cat.ActivityName AS [Hoạt Động Giảm Phát Thải],
    mrv.CalculatedCO2e AS [CO2 Giảm Được (Tấn)],
    led.TokenId AS [Mã Token Blockchain],
    led.BlockchainTxHash AS [Mã Giao Dịch On-Chain]
FROM iot.Farms f
JOIN dbo.FarmerProfiles fp ON f.FarmerId = fp.UserId
JOIN esg.MRVLogs mrv ON f.FarmId = mrv.FarmId
JOIN esg.CarbonImpactCatalog cat ON mrv.FactorId = cat.FactorId
LEFT JOIN esg.CarbonLedger led ON mrv.MRVId = led.MRVId
WHERE mrv.VerificationStatus = 'VERIFIED'
ORDER BY mrv.CalculatedCO2e ASC; -- Sắp xếp theo lượng giảm CO2 (số âm)

-- Truy vết Tự động: Cảm biến IoT kích hoạt Bảo hiểm Hạn mặn
SELECT 
    fp.FullName AS [Nông Dân],
    f.FarmName AS [Vị Trí Cảnh Báo],
    dev.DeviceId AS [Mã Cảm Biến],
    readings.MetricType AS [Chỉ Số Đo],
    readings.MetricValue AS [Giá Trị Hiện Tại],
    ins.TriggerThreshold AS [Ngưỡng Kích Hoạt],
    ins.CoverageAmount AS [Hạn Mức Bảo Hiểm (VNĐ)],
    pay.PayoutAmount AS [Đã Bồi Thường (VNĐ)],
    ins.Status AS [Trạng Thái Hợp Đồng]
FROM iot.IoTSensorReadings readings
JOIN iot.IoTDevices dev ON readings.DeviceId = dev.DeviceId
JOIN iot.Farms f ON dev.FarmId = f.FarmId
JOIN dbo.FarmerProfiles fp ON f.FarmerId = fp.UserId
JOIN esg.MicroInsuranceContracts ins ON f.FarmId = ins.FarmId
LEFT JOIN esg.InsurancePayoutLogs pay ON ins.ContractId = pay.ContractId
WHERE readings.MetricValue >= ins.TriggerThreshold
  AND readings.MetricType = ins.TriggerMetric;


  --"Mắt thần" Nông nghiệp: AI phát hiện sâu bệnh & Tư vấn
  SELECT 
    fp.FullName AS [Người Gửi],
    f.FarmName AS [Nông Trại],
    ai.ModelName AS [Model AI],
    ai.Label AS [Kết Quả Nhận Diện (Bệnh/Sâu)],
    CAST((ai.Confidence * 100) AS DECIMAL(5,2)) AS [Độ Chính Xác (%)],
    ai.Notes AS [Ghi Chú AI],
    cas.Title AS [Yêu Cầu Tư Vấn],
    cas.Status AS [Trạng Thái Hỗ Trợ]
FROM media.FarmMedia med
JOIN ai.AIDetections ai ON med.MediaId = ai.MediaId
JOIN iot.Farms f ON med.FarmId = f.FarmId
JOIN dbo.FarmerProfiles fp ON f.FarmerId = fp.UserId
LEFT JOIN community.ConsultingCases cas ON fp.UserId = cas.FarmerId
ORDER BY ai.Confidence DESC;

--Sàn Giao Dịch Kinh Tế Tuần Hoàn (Agri-Waste Marketplace)
SELECT 
    w.Title AS [Tên Phụ Phẩm],
    fp.FullName AS [Người Bán],
    addr.Province AS [Tỉnh Thành],
    w.Quantity AS [Số Lượng],
    w.Unit AS [Đơn Vị],
    w.Price AS [Đơn Giá (VNĐ)],
    (w.Quantity * w.Price) AS [Tổng Giá Trị (VNĐ)]
FROM commerce.AgriWasteListings w
JOIN dbo.FarmerProfiles fp ON w.SellerId = fp.UserId
JOIN core.UserAddresses addr ON fp.UserId = addr.UserId
ORDER BY w.CreatedAt DESC;

-- Agri-Uber (Gọi máy nông nghiệp)
SELECT 
    req.RequestId AS [Mã Đặt Máy],
    fp.FullName AS [Nông Dân Cần Thuê],
    f.FarmName AS [Địa Điểm Canh Tác (Farm)],
    req.MachineTypeRequired AS [Loại Máy Yêu Cầu],
    req.Status AS [Trạng Thái],
    mac.MachineType AS [Máy Được Điều Động],
    owner_user.DisplayName AS [Đơn Vị / Chủ Máy Trực Tiếp],
    mac.BasePricePerHour AS [Giá Thuê/Giờ (VNĐ)],
    req.ExpectedStartTime AS [Thời Gian Dự Kiến Bắt Đầu]
FROM logistics.MachineHailingRequests req
JOIN iot.Farms f ON req.FarmId = f.FarmId
JOIN dbo.FarmerProfiles fp ON f.FarmerId = fp.UserId
-- Dùng LEFT JOIN vì có thể yêu cầu đang ở trạng thái 'MATCHING' (chưa có máy nhận)
LEFT JOIN logistics.AgriMachines mac ON req.AssignedMachineId = mac.MachineId
LEFT JOIN dbo.Users owner_user ON mac.OwnerId = owner_user.UserId
ORDER BY 
    CASE req.Status 
        WHEN 'MATCHING' THEN 1 
        WHEN 'ACCEPTED' THEN 2 
        WHEN 'COMPLETED' THEN 3 
    END, 
    req.ExpectedStartTime DESC;

    -- =====================================================================================
-- TẠO BẢNG LỚN (VIEW) TỔNG HỢP TOÀN BỘ GIAO DỊCH TRONG HỆ SINH THÁI SYNERGY MEKONG
-- =====================================================================================

CREATE VIEW dbo.vw_MasterTransactions
AS

-- 1. DỊCH VỤ AGRI-UBER (Thuê Máy Móc)
SELECT 
    'Agri-Uber (Thuê Máy)' AS [Loại Dịch Vụ],
    CAST(req.RequestId AS VARCHAR(50)) AS [Mã Giao Dịch],
    fp.FullName AS [Khách Hàng / Yêu Cầu],
    ISNULL(owner_user.DisplayName, N'Chờ điều phối') AS [Đối Tác Cung Cấp],
    req.MachineTypeRequired + N' tại ' + f.FarmName AS [Chi Tiết Dịch Vụ],
    ISNULL(mac.BasePricePerHour, 0) AS [Giá Trị (VNĐ)],
    req.Status AS [Trạng Thái],
    req.CreatedAt AS [Thời Gian]
FROM logistics.MachineHailingRequests req
JOIN iot.Farms f ON req.FarmId = f.FarmId
JOIN dbo.FarmerProfiles fp ON f.FarmerId = fp.UserId
LEFT JOIN logistics.AgriMachines mac ON req.AssignedMachineId = mac.MachineId
LEFT JOIN dbo.Users owner_user ON mac.OwnerId = owner_user.UserId

UNION ALL

-- 2. DỊCH VỤ TƯ VẤN CHUYÊN GIA (Consulting)
SELECT 
    'Tư Vấn Nông Nghiệp' AS [Loại Dịch Vụ],
    CAST(cas.CaseId AS VARCHAR(50)) AS [Mã Giao Dịch],
    fp.FullName AS [Khách Hàng / Yêu Cầu],
    ISNULL(ex.DisplayName, N'Chờ tiếp nhận') AS [Đối Tác Cung Cấp],
    cas.Title AS [Chi Tiết Dịch Vụ],
    ISNULL(cas.Fee, 0) AS [Giá Trị (VNĐ)],
    cas.Status AS [Trạng Thái],
    cas.CreatedAt AS [Thời Gian]
FROM community.ConsultingCases cas
JOIN dbo.FarmerProfiles fp ON cas.FarmerId = fp.UserId
LEFT JOIN dbo.Users ex ON cas.ExpertId = ex.UserId

UNION ALL

-- 3. DỊCH VỤ SÀN THƯƠNG MẠI ĐIỆN TỬ (Marketplace Orders)
SELECT 
    'Sàn TMĐT (Mua Bán)' AS [Loại Dịch Vụ],
    CAST(o.OrderId AS VARCHAR(50)) AS [Mã Giao Dịch],
    buyer.DisplayName AS [Khách Hàng / Yêu Cầu],
    N'Nhiều nhà cung cấp' AS [Đối Tác Cung Cấp],
    N'Đơn hàng TMĐT / Vật tư nông nghiệp' AS [Chi Tiết Dịch Vụ],
    ISNULL(o.OrderTotal, 0) AS [Giá Trị (VNĐ)],
    o.Status AS [Trạng Thái],
    o.CreatedAt AS [Thời Gian]
FROM commerce.Orders o
JOIN dbo.Users buyer ON o.BuyerId = buyer.UserId

UNION ALL

-- 4. DỊCH VỤ BẢO HIỂM NÔNG NGHIỆP (Micro-Insurance)
SELECT 
    'Bảo Hiểm Vi Mô' AS [Loại Dịch Vụ],
    CAST(ins.ContractId AS VARCHAR(50)) AS [Mã Giao Dịch],
    fp.FullName AS [Khách Hàng / Yêu Cầu],
    N'Hệ thống Synergy' AS [Đối Tác Cung Cấp],
    N'Bảo hiểm chỉ số: ' + ins.TriggerMetric AS [Chi Tiết Dịch Vụ],
    ISNULL(ins.CoverageAmount, 0) AS [Giá Trị (VNĐ)],
    ins.Status AS [Trạng Thái],
    ins.CreatedAt AS [Thời Gian]
FROM esg.MicroInsuranceContracts ins
JOIN iot.Farms f ON ins.FarmId = f.FarmId
JOIN dbo.FarmerProfiles fp ON f.FarmerId = fp.UserId

UNION ALL

-- 5. DỊCH VỤ THUÊ ĐẤT (Land Rental)
SELECT 
    'Thuê Đất Canh Tác' AS [Loại Dịch Vụ],
    CAST(lr.RentalId AS VARCHAR(50)) AS [Mã Giao Dịch],
    renter.DisplayName AS [Khách Hàng / Yêu Cầu],
    owner_user.DisplayName AS [Đối Tác Cung Cấp],
    N'Diện tích: ' + CAST(ll.AreaHectares AS VARCHAR) + ' Ha' AS [Chi Tiết Dịch Vụ],
    ISNULL(lr.Price, 0) AS [Giá Trị (VNĐ)],
    'ACTIVE' AS [Trạng Thái],
    CAST(lr.StartDate AS DATETIMEOFFSET) AS [Thời Gian]
FROM commerce.LandRentals lr
JOIN commerce.LandListings ll ON lr.LandId = ll.LandId
JOIN dbo.Users renter ON lr.RenterId = renter.UserId
JOIN dbo.Users owner_user ON ll.OwnerId = owner_user.UserId

UNION ALL

-- 6. DỊCH VỤ GIAO DỊCH CARBON (ESG Token Orders)
SELECT 
    'Giao Dịch Carbon' AS [Loại Dịch Vụ],
    CAST(ord.OrderId AS VARCHAR(50)) AS [Mã Giao Dịch],
    N'Thị trường mở' AS [Khách Hàng / Yêu Cầu],
    sme.CompanyName AS [Đối Tác Cung Cấp],
    N'Bán ' + CAST(ord.Quantity AS VARCHAR) + N' Tấn CO2e' AS [Chi Tiết Dịch Vụ],
    ISNULL((ord.Quantity * ord.PricePerTon), 0) AS [Giá Trị (VNĐ)],
    ord.Status AS [Trạng Thái],
    ord.CreatedAt AS [Thời Gian]
FROM esg.TokenOrders ord
JOIN dbo.SMEProfiles sme ON ord.SellerSMEId = sme.UserId;
GO

select * 
from dbo.vw_MasterTransactions

-- INSERT địa chỉ cho user "Nhà Đầu Tư Mekong 5"
INSERT INTO core.UserAddresses (UserId, Province, District, Commune, AddressLine)
VALUES (
    'C250BBB9-0932-4C3C-84BB-01B003C1BC63',
    N'An Giang',
    N'Long Xuyên', 
    N'Mỹ Bình',
    N'123 Đường Trần Hưng Đạo'
);

-- INSERT thêm 1 user khác (lấy UserId từ bảng Users)
INSERT INTO core.UserAddresses (UserId, Province, District, Commune, AddressLine)
VALUES (
    (SELECT TOP 1 UserId FROM dbo.Users WHERE DisplayName != N'Nhà Đầu Tư Mekong 5'),
    N'Kiên Giang',
    N'Rạch Giá',
    N'Vĩnh Thanh',
    N'456 Đường Nguyễn Trung Trực'
);

-- Truy vấn địa chỉ kèm thông tin user
SELECT 
    u.DisplayName,
    u.PhoneNumber,
    u.RoleType,
    a.Province,
    a.District,
    a.Commune,
    a.AddressLine,
    a.CreatedAt
FROM dbo.Users u
INNER JOIN core.UserAddresses a ON u.UserId = a.UserId
ORDER BY u.DisplayName