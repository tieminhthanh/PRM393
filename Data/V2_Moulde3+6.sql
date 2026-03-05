-- ===================================================================
-- DIGITALVILLAGEDB - PHIÊN BẢN HOÀN CHỈNH (POLYMORPHIC IMAGES, CART, ORDERS)
-- Tự động sinh dữ liệu: 30 Sản phẩm, 160+ Hình ảnh, >=10 dòng/bảng khác
-- Target: SQL Server 2022
-- ===================================================================

IF DB_ID('DigitalVillageDBV2') IS NOT NULL
BEGIN
    ALTER DATABASE DigitalVillageDBV2 SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DigitalVillageDBV2;
END
GO

CREATE DATABASE DigitalVillageDBV2;
GO

USE DigitalVillageDBV2;
GO

-- =======================================================================
-- TẠO SCHEMA
-- =======================================================================
EXEC('CREATE SCHEMA core');
EXEC('CREATE SCHEMA iot');
EXEC('CREATE SCHEMA commerce');
EXEC('CREATE SCHEMA community');
EXEC('CREATE SCHEMA logistics');
GO

/* =======================================================================
   1. CORE & UNIFIED IMAGES (Hình ảnh tập trung)
   ======================================================================= */

CREATE TABLE dbo.Users (
    UserId        UNIQUEIDENTIFIER PRIMARY KEY,
    PhoneNumber   VARCHAR(20)      UNIQUE NOT NULL,
    Email         VARCHAR(200)     UNIQUE NULL,
    PasswordHash  VARBINARY(512)   NOT NULL,
    RoleType      VARCHAR(20)      NOT NULL CHECK (RoleType IN ('FARMER','SME','ADMIN')),
    DisplayName   NVARCHAR(200)    NULL,
    IsActive      BIT              NOT NULL DEFAULT 1,
    CreatedAt     DATETIMEOFFSET   NOT NULL DEFAULT SYSDATETIMEOFFSET()
);

-- BẢNG HÌNH ẢNH ĐA HÌNH (Dùng chung cho Sản phẩm, User, SME, v.v.)
CREATE TABLE dbo.Images (
    ImageId       UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    ReferenceId   UNIQUEIDENTIFIER NOT NULL, -- Chứa UserId, ProductId, SmeId...
    ReferenceType VARCHAR(50)      NOT NULL CHECK (ReferenceType IN ('USER', 'PRODUCT', 'SME', 'FARM', 'CONSULTING')),
    ImageUrl      NVARCHAR(500)    NOT NULL,
    IsPrimary     BIT              DEFAULT 0, -- 1 là ảnh bìa/avatar hiện tại
    DisplayOrder  INT              DEFAULT 0,
    UploadedAt    DATETIMEOFFSET   DEFAULT SYSDATETIMEOFFSET()
);
CREATE NONCLUSTERED INDEX IX_Images_Reference ON dbo.Images(ReferenceType, ReferenceId);

CREATE TABLE core.UserAddresses (
    AddressId   UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    UserId      UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES dbo.Users(UserId),
    Province    NVARCHAR(100),
    District    NVARCHAR(100),
    Commune     NVARCHAR(100),
    AddressLine NVARCHAR(300),
    CreatedAt   DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET()
);

CREATE TABLE dbo.FarmerProfiles (
    UserId         UNIQUEIDENTIFIER PRIMARY KEY FOREIGN KEY REFERENCES dbo.Users(UserId),
    FullName       NVARCHAR(200) NOT NULL,
    Village        NVARCHAR(200) NULL,
    ContactName    NVARCHAR(200) NULL,
    ContactPhone   VARCHAR(20)   NULL,
    PreferredVoice BIT DEFAULT 1
);

CREATE TABLE dbo.SMEProfiles (
    UserId          UNIQUEIDENTIFIER PRIMARY KEY FOREIGN KEY REFERENCES dbo.Users(UserId),
    CompanyName     NVARCHAR(300) NOT NULL,
    TaxCode         VARCHAR(50)   UNIQUE NOT NULL,
    ContactName     NVARCHAR(200) NULL,
    ContactPhone    VARCHAR(20)   NULL,
    AddressSummary  NVARCHAR(300) NULL
);

/* =======================================================================
   2. IOT & NÔNG NGHIỆP
   ======================================================================= */

CREATE TABLE iot.Farms (
    FarmId         UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    FarmerId       UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES dbo.FarmerProfiles(UserId),
    FarmName       NVARCHAR(200),
    Location       GEOGRAPHY NULL,
    AreaHectares   DECIMAL(9,2)  NOT NULL,
    CropType       NVARCHAR(100),
    Certifications NVARCHAR(200) NULL
);

CREATE TABLE iot.IoTDevices (
    DeviceId     VARCHAR(50)      PRIMARY KEY,
    FarmId       UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES iot.Farms(FarmId),
    DeviceType   VARCHAR(50)      CHECK (DeviceType IN ('SOIL','AIR','WATER','GATEWAY')),
    BatteryLevel TINYINT          CHECK (BatteryLevel BETWEEN 0 AND 100)
);

CREATE TABLE iot.IoTSensorReadings (
    ReadingId   BIGINT IDENTITY(1,1) PRIMARY KEY,
    DeviceId    VARCHAR(50)    NOT NULL FOREIGN KEY REFERENCES iot.IoTDevices(DeviceId),
    MetricType  VARCHAR(50)    NOT NULL,
    MetricValue DECIMAL(18,6)  NOT NULL,
    RecordedAt  DATETIMEOFFSET NOT NULL DEFAULT SYSDATETIMEOFFSET()
);

CREATE TABLE iot.FarmingLogs (
    LogId          UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    FarmId         UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES iot.Farms(FarmId),
    ActionType     NVARCHAR(200)    NOT NULL,
    MaterialUsed   NVARCHAR(200)    NULL,
    Quantity       DECIMAL(18,4)    NULL,
    RecordedAt     DATETIMEOFFSET   NOT NULL DEFAULT SYSDATETIMEOFFSET()
);

/* =======================================================================
   3. LOGISTICS (Thuê máy móc)
   ======================================================================= */

CREATE TABLE logistics.AgriMachines (
    MachineId         UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    OwnerId           UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES dbo.Users(UserId),
    MachineType       NVARCHAR(100)    NOT NULL,
    BasePricePerHour  DECIMAL(18,2)    NOT NULL
);

CREATE TABLE logistics.MachineHailingRequests (
    RequestId           UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    FarmId              UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES iot.Farms(FarmId),
    MachineTypeRequired NVARCHAR(100)    NOT NULL,
    ExpectedStartTime   DATETIMEOFFSET   NOT NULL,
    Status              VARCHAR(20)      DEFAULT 'MATCHING'
);

/* =======================================================================
   4. COMMERCE (Sản phẩm, Giỏ hàng, Đơn hàng)
   ======================================================================= */

CREATE TABLE commerce.Products (
    ProductId   UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    SellerId    UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES dbo.Users(UserId),
    Title       NVARCHAR(300)    NOT NULL,
    Description NVARCHAR(MAX)    NULL,
    Category    NVARCHAR(100)    NULL,
    Price       DECIMAL(18,2)    NOT NULL,
    Unit        NVARCHAR(50)     NULL,
    CreatedAt   DATETIMEOFFSET   DEFAULT SYSDATETIMEOFFSET()
);

CREATE TABLE commerce.ProductBatches (
    ProductBatchId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    ProductId      UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES commerce.Products(ProductId),
    BatchCode      VARCHAR(200)     UNIQUE,
    ProductionDate DATE             NULL
);

-- GIỎ HÀNG
CREATE TABLE commerce.Carts (
    CartId      UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    UserId      UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES dbo.Users(UserId),
    UpdatedAt   DATETIMEOFFSET   DEFAULT SYSDATETIMEOFFSET()
);

CREATE TABLE commerce.CartItems (
    CartItemId  UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    CartId      UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES commerce.Carts(CartId),
    ProductId   UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES commerce.Products(ProductId),
    Quantity    DECIMAL(18,4)    NOT NULL
);

-- ĐƠN HÀNG & THANH TOÁN
CREATE TABLE commerce.Orders (
    OrderId     UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    BuyerId     UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES dbo.Users(UserId),
    OrderTotal  DECIMAL(18,2)    NOT NULL,
    Status      VARCHAR(50)      DEFAULT 'CREATED',
    CreatedAt   DATETIMEOFFSET   DEFAULT SYSDATETIMEOFFSET()
);

CREATE TABLE commerce.OrderItems (
    OrderItemId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    OrderId     UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES commerce.Orders(OrderId),
    ProductId   UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES commerce.Products(ProductId),
    Quantity    DECIMAL(18,4)    NOT NULL,
    Price       DECIMAL(18,2)    NOT NULL
);

CREATE TABLE commerce.Payments (
    PaymentId         UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    OrderId           UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES commerce.Orders(OrderId),
    Amount            DECIMAL(18,2)    NOT NULL,
    Provider          VARCHAR(100),
    PaidAt            DATETIMEOFFSET   DEFAULT SYSDATETIMEOFFSET()
);

-- ĐẤT & CHỨNG NHẬN
CREATE TABLE commerce.Certificates (
    CertificateId   UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    SellerId        UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES dbo.Users(UserId),
    CertificateType VARCHAR(200)
);

CREATE TABLE commerce.LandListings (
    LandId          UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    OwnerId         UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES dbo.Users(UserId),
    AreaHectares    DECIMAL(9,2)     NOT NULL,
    PricePerHectare DECIMAL(18,2)    NULL
);

CREATE TABLE commerce.LandRentals (
    RentalId  UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    LandId    UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES commerce.LandListings(LandId),
    RenterId  UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES dbo.Users(UserId),
    StartDate DATE
);

/* =======================================================================
   5. COMMUNITY & SYSTEM
   ======================================================================= */

CREATE TABLE community.ConsultingCases (
    CaseId      UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    FarmerId    UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES dbo.FarmerProfiles(UserId),
    Title       NVARCHAR(300),
    Status      VARCHAR(50)      DEFAULT 'OPEN'
);

CREATE TABLE dbo.NotificationChannels (
    ChannelId INT IDENTITY(1,1) PRIMARY KEY,
    Name      VARCHAR(50)
);

CREATE TABLE dbo.Notifications (
    NotificationId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    UserId         UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES dbo.Users(UserId),
    Title          NVARCHAR(300),
    IsRead         BIT DEFAULT 0
);

CREATE TABLE dbo.AuditLogs (
    AuditId     BIGINT IDENTITY(1,1) PRIMARY KEY,
    Action      NVARCHAR(100),
    Details     NVARCHAR(MAX)
);

GO

/* =======================================================================
   TẠO DỮ LIỆU MẪU (SEEDING DATA) CHO TẤT CẢ CÁC BẢNG (Ít nhất 10 dòng)
   ======================================================================= */

-- 1. USERS (10 Users: 5 Farmer, 5 SME/Admin)
INSERT INTO dbo.Users (UserId, PhoneNumber, Email, PasswordHash, RoleType, DisplayName) VALUES
('11111111-1111-1111-1111-111111111111', '0901000001', 'farmer1@test.com', 0x01, 'FARMER', N'Nguyễn Văn Trồng'),
('22222222-2222-2222-2222-222222222222', '0901000002', 'farmer2@test.com', 0x01, 'FARMER', N'Trần Thị Cấy'),
('33333333-3333-3333-3333-333333333333', '0901000003', 'farmer3@test.com', 0x01, 'FARMER', N'Lê Văn Thu'),
('44444444-4444-4444-4444-444444444444', '0901000004', 'farmer4@test.com', 0x01, 'FARMER', N'Phạm Văn Vụ'),
('55555555-5555-5555-5555-555555555555', '0901000005', 'farmer5@test.com', 0x01, 'FARMER', N'Hoàng Thị Mùa'),
('66666666-6666-6666-6666-666666666666', '0901000006', 'sme1@test.com', 0x01, 'SME', N'CTY Nông Sản Xanh'),
('77777777-7777-7777-7777-777777777777', '0901000007', 'sme2@test.com', 0x01, 'SME', N'HTX Nông Nghiệp Tương Lai'),
('88888888-8888-8888-8888-888888888888', '0901000008', 'sme3@test.com', 0x01, 'SME', N'Kho Lạnh Miền Tây'),
('99999999-9999-9999-9999-999999999999', '0901000009', 'sme4@test.com', 0x01, 'SME', N'Phân Phối Lúa Gạo VN'),
('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA', '0901000010', 'admin1@test.com', 0x01, 'ADMIN', N'Quản trị viên Hệ thống');

-- 2. ĐỊA CHỈ & PROFILE (10 dòng)
INSERT INTO core.UserAddresses (UserId, Province, District)
SELECT UserId, N'TP HCM', N'Quận 1' FROM dbo.Users;

INSERT INTO dbo.FarmerProfiles (UserId, FullName, Village)
SELECT UserId, DisplayName, N'Làng Nông Nghiệp' FROM dbo.Users WHERE RoleType = 'FARMER';

INSERT INTO dbo.SMEProfiles (UserId, CompanyName, TaxCode)
SELECT UserId, DisplayName, 'TAX' + CAST(ROW_NUMBER() OVER(ORDER BY UserId) AS VARCHAR) FROM dbo.Users WHERE RoleType IN ('SME', 'ADMIN');

-- 3. HÌNH ẢNH USER (Lưu vào bảng đa hình Images) - Ít nhất 10 hình
INSERT INTO dbo.Images (ReferenceId, ReferenceType, ImageUrl, IsPrimary)
SELECT UserId, 'USER', 'https://loremflickr.com/300/300/face,portrait?lock=' + CAST(ABS(CHECKSUM(NEWID())) % 1000 AS VARCHAR), 1
FROM dbo.Users;

-- 4. BẢNG PRODUCTS VÀ HÌNH ẢNH SẢN PHẨM (30 Sản phẩm x 5 Hình = 150 Hình)
CREATE TABLE #TempProducts (
    ProductId UNIQUEIDENTIFIER DEFAULT NEWID() PRIMARY KEY,
    Title NVARCHAR(300), Category NVARCHAR(100), Price DECIMAL(18,2), EngKeyword VARCHAR(50)
);

INSERT INTO #TempProducts (Title, Category, Price, EngKeyword) VALUES
(N'Xoài Cát', N'Trái Cây', 50000, 'mango'), (N'Sầu Riêng', N'Trái Cây', 120000, 'durian'),
(N'Bơ Sáp', N'Trái Cây', 40000, 'avocado'), (N'Thanh Long', N'Trái Cây', 25000, 'dragonfruit'),
(N'Bưởi Da Xanh', N'Trái Cây', 60000, 'pomelo'), (N'Dưa Hấu', N'Trái Cây', 15000, 'watermelon'),
(N'Chuối', N'Trái Cây', 20000, 'banana'), (N'Mít Thái', N'Trái Cây', 30000, 'jackfruit'),
(N'Nho Xanh', N'Trái Cây', 70000, 'grape'), (N'Cam Sành', N'Trái Cây', 25000, 'orange'),
(N'Chôm Chôm', N'Trái Cây', 35000, 'rambutan'), (N'Dừa Sáp', N'Trái Cây', 150000, 'coconut'),
(N'Cà Chua', N'Rau Củ', 40000, 'tomato'), (N'Dưa Leo', N'Rau Củ', 20000, 'cucumber'),
(N'Cà Rốt', N'Rau Củ', 25000, 'carrot'), (N'Khoai Tây', N'Rau Củ', 30000, 'potato'),
(N'Hành Tây', N'Rau Củ', 18000, 'onion'), (N'Tỏi Cô Đơn', N'Gia Vị', 150000, 'garlic'),
(N'Ớt Chuông', N'Rau Củ', 50000, 'bellpepper'), (N'Bắp Cải', N'Rau Củ', 20000, 'cabbage'),
(N'Cải Bó Xôi', N'Rau Củ', 25000, 'spinach'), (N'Xà Lách', N'Rau Củ', 30000, 'lettuce'),
(N'Nấm Mối', N'Rau Củ', 200000, 'mushroom'), (N'Gạo ST25', N'Ngũ Cốc', 35000, 'rice'),
(N'Hạt Điều', N'Hạt', 250000, 'cashew'), (N'Cà Phê', N'Nông Sản Phái Sinh', 150000, 'coffee'),
(N'Hạt Tiêu', N'Gia Vị', 100000, 'blackpepper'), (N'Trà Oolong', N'Trà', 300000, 'tea'),
(N'Mật Ong', N'Đặc Sản', 250000, 'honey'), (N'Phân Bón', N'Vật Tư', 15000, 'fertilizer');

-- Gán sản phẩm ngẫu nhiên cho 5 user đầu tiên (Farmer)
INSERT INTO commerce.Products (ProductId, SellerId, Title, Category, Price, Unit)
SELECT p.ProductId, u.UserId, p.Title, p.Category, p.Price, N'Kg'
FROM #TempProducts p
CROSS APPLY (SELECT TOP 1 UserId FROM dbo.Users WHERE RoleType = 'FARMER' ORDER BY NEWID()) u;

-- Chèn 150 hình ảnh sản phẩm vào bảng ĐA HÌNH Images
INSERT INTO dbo.Images (ReferenceId, ReferenceType, ImageUrl, IsPrimary, DisplayOrder)
SELECT 
    p.ProductId, 'PRODUCT', 
    'https://loremflickr.com/600/600/' + p.EngKeyword + '?lock=' + CAST(v.number AS VARCHAR),
    IIF(v.number = 1, 1, 0), v.number
FROM #TempProducts p CROSS JOIN (VALUES (1),(2),(3),(4),(5)) AS v(number);

DROP TABLE #TempProducts;

-- 5. GIỎ HÀNG (Mỗi User có 1 Cart -> 10 Carts. Mỗi Cart chèn ngẫu nhiên 2 Items -> >10 CartItems)
INSERT INTO commerce.Carts (CartId, UserId) SELECT NEWID(), UserId FROM dbo.Users;

INSERT INTO commerce.CartItems (CartId, ProductId, Quantity)
SELECT c.CartId, p.ProductId, 5
FROM commerce.Carts c
CROSS APPLY (SELECT TOP 2 ProductId FROM commerce.Products ORDER BY NEWID()) p;

-- 6. ĐƠN HÀNG VÀ THANH TOÁN (Sinh 10 Đơn hàng, 10 Items, 10 Thanh toán)
INSERT INTO commerce.Orders (OrderId, BuyerId, OrderTotal)
SELECT TOP 10 NEWID(), UserId, 500000 FROM dbo.Users ORDER BY NEWID();

INSERT INTO commerce.OrderItems (OrderId, ProductId, Quantity, Price)
SELECT o.OrderId, p.ProductId, 2, 250000
FROM commerce.Orders o
CROSS APPLY (SELECT TOP 1 ProductId FROM commerce.Products ORDER BY NEWID()) p;

INSERT INTO commerce.Payments (OrderId, Amount, Provider)
SELECT OrderId, OrderTotal, 'VNPAY' FROM commerce.Orders;

-- 7. IOT, LOGISTICS VÀ CÁC BẢNG KHÁC (Đảm bảo mỗi bảng có 10 dòng)
-- 10 Nông trại
INSERT INTO iot.Farms (FarmId, FarmerId, FarmName, AreaHectares, CropType)
SELECT TOP 10 NEWID(), UserId, N'Nông trại ' + DisplayName, 1.5, N'Hỗn hợp'
FROM dbo.Users CROSS JOIN (VALUES (1),(2)) v(n) WHERE RoleType = 'FARMER';

-- 10 Thiết bị IoT
INSERT INTO iot.IoTDevices (DeviceId, FarmId, DeviceType, BatteryLevel)
SELECT TOP 10 'DEV-' + CAST(NEWID() AS VARCHAR(36)), FarmId, 'SOIL', 85 FROM iot.Farms;

-- 10 Lịch sử đọc cảm biến
INSERT INTO iot.IoTSensorReadings (DeviceId, MetricType, MetricValue)
SELECT DeviceId, 'MOISTURE', 65.5 FROM iot.IoTDevices;

-- 10 Nhật ký canh tác
INSERT INTO iot.FarmingLogs (FarmId, ActionType, Quantity)
SELECT FarmId, N'Tưới nước', 100 FROM iot.Farms;

-- 10 Máy móc nông nghiệp
INSERT INTO logistics.AgriMachines (OwnerId, MachineType, BasePricePerHour)
SELECT TOP 10 UserId, N'Máy Cày Tự Động', 500000 FROM dbo.Users CROSS JOIN (VALUES(1),(2)) v(n) WHERE RoleType = 'SME';

-- 10 Yêu cầu thuê máy
INSERT INTO logistics.MachineHailingRequests (FarmId, MachineTypeRequired, ExpectedStartTime)
SELECT FarmId, N'Máy Cày Tự Động', SYSDATETIMEOFFSET() FROM iot.Farms;

-- 10 Lô hàng sản xuất
INSERT INTO commerce.ProductBatches (ProductId, BatchCode)
SELECT TOP 10 ProductId, 'BATCH-' + CAST(NEWID() AS VARCHAR(36)) FROM commerce.Products;

-- 10 Đất cho thuê và Hợp đồng
INSERT INTO commerce.LandListings (LandId, OwnerId, AreaHectares, PricePerHectare)
SELECT TOP 10 NEWID(), UserId, 5.0, 10000000 FROM dbo.Users;

INSERT INTO commerce.LandRentals (LandId, RenterId, StartDate)
SELECT LandId, (SELECT TOP 1 UserId FROM dbo.Users ORDER BY NEWID()), GETDATE() FROM commerce.LandListings;

-- 10 Chứng nhận
INSERT INTO commerce.Certificates (SellerId, CertificateType)
SELECT UserId, 'VietGAP' FROM dbo.Users;

-- 10 Ca tư vấn
INSERT INTO community.ConsultingCases (FarmerId, Title)
SELECT TOP 10 UserId, N'Tư vấn sâu bệnh' FROM dbo.FarmerProfiles CROSS JOIN (VALUES(1),(2)) v(n);

-- Channels & Notifications & Audit (>= 10 dòng)
INSERT INTO dbo.NotificationChannels (Name) VALUES ('EMAIL'), ('SMS'), ('PUSH_NOTIFICATION');

INSERT INTO dbo.Notifications (UserId, Title)
SELECT UserId, N'Chào mừng bạn đến với Nông Thôn Số!' FROM dbo.Users;

INSERT INTO dbo.AuditLogs (Action, Details)
SELECT TOP 10 'USER_LOGIN', N'Đăng nhập hệ thống' FROM dbo.Users;

GO

USE DigitalVillageDBV2;
GO

-- Lấy ID của một User để test (Ví dụ: Nguyễn Văn Trồng)
DECLARE @TargetUserId UNIQUEIDENTIFIER = '11111111-1111-1111-1111-111111111111';

SELECT 
    p.Title AS [Tên Sản Phẩm],
    p.Category AS [Danh Mục],
    p.Price AS [Đơn Giá (VNĐ)],
    ci.Quantity AS [Số Lượng Trong Giỏ],
    (p.Price * ci.Quantity) AS [Thành Tiền (VNĐ)],
    i.ImageUrl AS [Link Ảnh Đại Diện]
FROM commerce.Carts c
-- 1. Kết nối Giỏ hàng với Chi tiết giỏ hàng
INNER JOIN commerce.CartItems ci 
    ON c.CartId = ci.CartId
-- 2. Kết nối lấy thông tin Sản phẩm
INNER JOIN commerce.Products p 
    ON ci.ProductId = p.ProductId
-- 3. ĐIỂM SÁNG CỦA ĐA HÌNH: Kết nối lấy đúng 1 ảnh bìa của sản phẩm đó
LEFT JOIN dbo.Images i 
    ON p.ProductId = i.ReferenceId 
    AND i.ReferenceType = 'PRODUCT' 
    AND i.IsPrimary = 1
WHERE c.UserId = @TargetUserId;

Select *
from [commerce].[Products]


Select *
from [dbo].[Images]
where [ReferenceId]='DFE9C0C1-2A95-4550-9F05-A41D070B8D9F'
