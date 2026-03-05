/* =============================================================
   PRM393 - FULL DATABASE SCRIPT
   SQL Server | Unicode Vietnamese Support (NVARCHAR + N'...')
   ============================================================= */

/* =========================================
   1. KIỂM TRA & XÓA DATABASE CŨ
   ========================================= */
IF EXISTS (
    SELECT name FROM sys.databases WHERE name = 'prm393'
)
BEGIN
    ALTER DATABASE prm393 SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE prm393;
END
GO

/* =========================================
   2. TẠO DATABASE MỚI (UTF-8 / Vietnamese)
   ========================================= */
CREATE DATABASE prm393
    COLLATE Vietnamese_CI_AS;
GO

USE prm393;
GO

/* =============================================================
   PHẦN I: TẠO BẢNG
   ============================================================= */

/* =========================================================
   1. USERS
   ========================================================= */
CREATE TABLE Users (
    UserId       INT IDENTITY(1,1) PRIMARY KEY,
    PhoneNumber  NVARCHAR(20)  UNIQUE NOT NULL,
    Email        NVARCHAR(255) UNIQUE NULL,
    PasswordHash VARBINARY(MAX) NOT NULL,
    RoleType     NVARCHAR(20)  NOT NULL
                     CHECK (RoleType IN ('FARMER','SME','ADMIN')),
    DisplayName  NVARCHAR(255),
    IsActive     BIT          NOT NULL DEFAULT 1,
    CreatedAt    DATETIME     DEFAULT GETDATE()
);

/* =========================================================
   2. ADMIN PROFILES
   ========================================================= */
CREATE TABLE AdminProfiles (
    AdminId   INT PRIMARY KEY,
    FullName  NVARCHAR(255) NOT NULL,
    Position  NVARCHAR(255),
    CreatedAt DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (AdminId) REFERENCES Users(UserId)
);

/* =========================================================
   3. USER ADDRESSES
   ========================================================= */
CREATE TABLE core_UserAddresses (
    AddressId   INT IDENTITY(1,1) PRIMARY KEY,
    UserId      INT NOT NULL,
    Province    NVARCHAR(255),
    District    NVARCHAR(255),
    Commune     NVARCHAR(255),
    AddressLine NVARCHAR(255),
    CreatedAt   DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (UserId) REFERENCES Users(UserId)
);

/* =========================================================
   4. FARMER PROFILES
   ========================================================= */
CREATE TABLE FarmerProfiles (
    UserId         INT PRIMARY KEY,
    FullName       NVARCHAR(255) NOT NULL,
    Village        NVARCHAR(255),
    ContactName    NVARCHAR(255),
    ContactPhone   NVARCHAR(20),
    PreferredVoice BIT DEFAULT 1,
    FOREIGN KEY (UserId) REFERENCES Users(UserId)
);

/* =========================================================
   5. SME PROFILES
   ========================================================= */
CREATE TABLE SMEProfiles (
    UserId         INT PRIMARY KEY,
    CompanyName    NVARCHAR(255) NOT NULL,
    TaxCode        NVARCHAR(50)  UNIQUE NOT NULL,
    ContactName    NVARCHAR(255),
    ContactPhone   NVARCHAR(20),
    AddressSummary NVARCHAR(500),
    FOREIGN KEY (UserId) REFERENCES Users(UserId)
);

/* =========================================================
   6. IMAGES
   ========================================================= */
CREATE TABLE Images (
    ImageId       INT IDENTITY(1,1) PRIMARY KEY,
    ReferenceId   INT          NOT NULL,
    ReferenceType NVARCHAR(20)
        CHECK (ReferenceType IN ('USER','PRODUCT','SME','FARM','CONSULTING','MACHINE')),
    ImageUrl      NVARCHAR(MAX) NOT NULL,
    IsPrimary     BIT  DEFAULT 0,
    DisplayOrder  INT  DEFAULT 0,
    UploadedAt    DATETIME DEFAULT GETDATE()
);

CREATE INDEX IX_Images_Reference
    ON Images(ReferenceType, ReferenceId);

/* =========================================================
   7. IOT FARMS
   ========================================================= */
CREATE TABLE iot_Farms (
    FarmId         INT IDENTITY(1,1) PRIMARY KEY,
    FarmerId       INT NOT NULL,
    FarmName       NVARCHAR(255),
    Location       NVARCHAR(255),
    AreaHectares   FLOAT NOT NULL,
    CropType       NVARCHAR(255),
    Certifications NVARCHAR(255),
    FOREIGN KEY (FarmerId) REFERENCES FarmerProfiles(UserId)
);

/* =========================================================
   8. IOT DEVICES
   ========================================================= */
CREATE TABLE iot_IoTDevices (
    DeviceId     INT IDENTITY(1,1) PRIMARY KEY,
    FarmId       INT NOT NULL,
    DeviceType   NVARCHAR(20)
        CHECK (DeviceType IN ('SOIL','AIR','WATER','GATEWAY')),
    Description  NVARCHAR(500),
    BatteryLevel INT CHECK (BatteryLevel BETWEEN 0 AND 100),
    FOREIGN KEY (FarmId) REFERENCES iot_Farms(FarmId)
);

/* =========================================================
   9. IOT SENSOR READINGS
   ========================================================= */
CREATE TABLE iot_IoTSensorReadings (
    ReadingId   INT IDENTITY(1,1) PRIMARY KEY,
    DeviceId    INT          NOT NULL,
    MetricType  NVARCHAR(100) NOT NULL,
    MetricValue FLOAT        NOT NULL,
    RecordedAt  DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (DeviceId) REFERENCES iot_IoTDevices(DeviceId)
);

/* =========================================================
   10. FARMING LOGS
   ========================================================= */
CREATE TABLE iot_FarmingLogs (
    LogId        INT IDENTITY(1,1) PRIMARY KEY,
    FarmId       INT          NOT NULL,
    ActionType   NVARCHAR(255) NOT NULL,
    MaterialUsed NVARCHAR(255),
    Quantity     FLOAT,
    RecordedAt   DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (FarmId) REFERENCES iot_Farms(FarmId)
);

/* =========================================================
   11. AGRI MACHINES
   ========================================================= */
CREATE TABLE logistics_AgriMachines (
    MachineId        INT IDENTITY(1,1) PRIMARY KEY,
    OwnerId          INT NOT NULL,
    MachineType      NVARCHAR(255) NOT NULL,
    Description      NVARCHAR(500),
    BasePricePerHour FLOAT NOT NULL,
    FOREIGN KEY (OwnerId) REFERENCES Users(UserId)
);

/* =========================================================
   12. MACHINE HAILING REQUESTS
   ========================================================= */
CREATE TABLE logistics_MachineHailingRequests (
    RequestId           INT IDENTITY(1,1) PRIMARY KEY,
    FarmId              INT NOT NULL,
    MachineTypeRequired NVARCHAR(255) NOT NULL,
    ExpectedStartTime   DATETIME NOT NULL,
    Status              NVARCHAR(50) DEFAULT 'MATCHING',
    FOREIGN KEY (FarmId) REFERENCES iot_Farms(FarmId)
);

/* =========================================================
   13. MACHINE BOOKINGS
   ========================================================= */
CREATE TABLE logistics_MachineBookings (
    BookingId  INT IDENTITY(1,1) PRIMARY KEY,
    MachineId  INT NOT NULL,
    FarmId     INT NOT NULL,
    BookerId   INT NOT NULL,
    StartTime  DATETIME NOT NULL,
    EndTime    DATETIME,
    TotalPrice FLOAT,
    Status     NVARCHAR(50) DEFAULT 'BOOKED',
    CreatedAt  DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (MachineId) REFERENCES logistics_AgriMachines(MachineId),
    FOREIGN KEY (FarmId)    REFERENCES iot_Farms(FarmId),
    FOREIGN KEY (BookerId)  REFERENCES Users(UserId)
);

/* =========================================================
   14. PRODUCTS
   ========================================================= */
CREATE TABLE commerce_Products (
    ProductId   INT IDENTITY(1,1) PRIMARY KEY,
    SellerId    INT NOT NULL,
    Title       NVARCHAR(255) NOT NULL,
    Description NVARCHAR(MAX),
    Category    NVARCHAR(255),
    Price       FLOAT NOT NULL,
    Unit        NVARCHAR(50),
    CreatedAt   DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (SellerId) REFERENCES Users(UserId)
);

/* =========================================================
   15. PRODUCT BATCHES
   ========================================================= */
CREATE TABLE commerce_ProductBatches (
    ProductBatchId INT IDENTITY(1,1) PRIMARY KEY,
    ProductId      INT NOT NULL,
    BatchCode      NVARCHAR(100) UNIQUE,
    ProductionDate DATETIME,
    FOREIGN KEY (ProductId) REFERENCES commerce_Products(ProductId)
);

/* =========================================================
   16. CARTS
   ========================================================= */
CREATE TABLE commerce_Carts (
    CartId    INT IDENTITY(1,1) PRIMARY KEY,
    UserId    INT NOT NULL,
    CreatedAt DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (UserId) REFERENCES Users(UserId)
);

/* =========================================================
   17. CART ITEMS
   ========================================================= */
CREATE TABLE commerce_CartItems (
    CartItemId INT IDENTITY(1,1) PRIMARY KEY,
    CartId     INT NOT NULL,
    ProductId  INT NOT NULL,
    Quantity   FLOAT NOT NULL,
    AddedAt    DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (CartId)    REFERENCES commerce_Carts(CartId),
    FOREIGN KEY (ProductId) REFERENCES commerce_Products(ProductId),
    CONSTRAINT UQ_Cart_Product UNIQUE (CartId, ProductId)
);

/* =========================================================
   18. ORDERS
   ========================================================= */
CREATE TABLE commerce_Orders (
    OrderId    INT IDENTITY(1,1) PRIMARY KEY,
    BuyerId    INT NOT NULL,
    OrderTotal FLOAT NOT NULL,
    Status     NVARCHAR(50) DEFAULT 'CREATED',
    CreatedAt  DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (BuyerId) REFERENCES Users(UserId)
);

/* =========================================================
   19. ORDER ITEMS
   ========================================================= */
CREATE TABLE commerce_OrderItems (
    OrderItemId INT IDENTITY(1,1) PRIMARY KEY,
    OrderId     INT NOT NULL,
    ProductId   INT NOT NULL,
    Quantity    FLOAT NOT NULL,
    Price       FLOAT NOT NULL,
    FOREIGN KEY (OrderId)   REFERENCES commerce_Orders(OrderId),
    FOREIGN KEY (ProductId) REFERENCES commerce_Products(ProductId)
);

/* =========================================================
   20. NOTIFICATIONS
   ========================================================= */
CREATE TABLE Notifications (
    NotificationId INT IDENTITY(1,1) PRIMARY KEY,
    UserId    INT NOT NULL,
    Title     NVARCHAR(255),
    IsRead    BIT DEFAULT 0,
    CreatedAt DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (UserId) REFERENCES Users(UserId)
);
GO


/* =============================================================
   PHẦN II: INSERT DỮ LIỆU MẪU
   ============================================================= */

/* =========================================================
   1. USERS (4 Farmer | 4 SME | 2 Admin)
   ========================================================= */
INSERT INTO Users (PhoneNumber, Email, PasswordHash, RoleType, DisplayName)
VALUES
('0901000001', N'farmer1@agri.vn', HASHBYTES('SHA2_256','Abcd1234@'), 'FARMER', N'Nguyễn Văn Tèo'),
('0901000002', N'farmer2@agri.vn', HASHBYTES('SHA2_256','Abcd1234@'), 'FARMER', N'Trần Thị Thắm'),
('0901000003', N'farmer3@agri.vn', HASHBYTES('SHA2_256','Abcd1234@'), 'FARMER', N'Lê Văn Hùng'),
('0901000004', N'farmer4@agri.vn', HASHBYTES('SHA2_256','Abcd1234@'), 'FARMER', N'Phạm Thị Hoa'),
('0911000001', N'sme1@agri.vn',    HASHBYTES('SHA2_256','Abcd1234@'), 'SME',    N'HTX Nông Nghiệp Xanh'),
('0911000002', N'sme2@agri.vn',    HASHBYTES('SHA2_256','Abcd1234@'), 'SME',    N'Công Ty Cơ Khí Vina'),
('0911000003', N'sme3@agri.vn',    HASHBYTES('SHA2_256','Abcd1234@'), 'SME',    N'Phân Bón Miền Nam'),
('0911000004', N'sme4@agri.vn',    HASHBYTES('SHA2_256','Abcd1234@'), 'SME',    N'Logistics Nông Thôn'),
('0888000001', N'admin1@system.com',HASHBYTES('SHA2_256','Abcd1234@'),'ADMIN',  N'Admin Vận Hành'),
('0888000002', N'admin2@system.com',HASHBYTES('SHA2_256','Abcd1234@'),'ADMIN',  N'Admin Kỹ Thuật');

/* =========================================================
   2. FARMER PROFILES
   ========================================================= */
INSERT INTO FarmerProfiles (UserId, FullName, Village, ContactPhone)
VALUES
(1, N'Nguyễn Văn Tèo', N'Thôn 1, Đắk Lắk',      '0901000001'),
(2, N'Trần Thị Thắm',  N'Xóm Chùa, Nam Định',     '0901000002'),
(3, N'Lê Văn Hùng',    N'Ấp 3, Tiền Giang',       '0901000003'),
(4, N'Phạm Thị Hoa',   N'Bản Lác, Hòa Bình',      '0901000004');

/* =========================================================
   3. SME PROFILES
   ========================================================= */
INSERT INTO SMEProfiles (UserId, CompanyName, TaxCode, ContactName)
VALUES
(5, N'HTX Nông Nghiệp Xanh', '0101010101', N'Ông Bình'),
(6, N'Công Ty Cơ Khí Vina',  '0202020202', N'Bà An'),
(7, N'Phân Bón Miền Nam',    '0303030303', N'Anh Dũng'),
(8, N'Logistics Nông Thôn',  '0404040404', N'Anh Hoàng');

/* =========================================================
   4. ADMIN PROFILES
   ========================================================= */
INSERT INTO AdminProfiles (AdminId, FullName, Position)
VALUES
(9,  N'Quản Trị Vận Hành', N'Trưởng phòng Vận hành'),
(10, N'Quản Trị Kỹ Thuật', N'Trưởng phòng IT');

/* =========================================================
   5. USER ADDRESSES
   ========================================================= */
INSERT INTO core_UserAddresses (UserId, Province, District, Commune, AddressLine)
VALUES
(1,  N'Đắk Lắk',       N'Buôn Ma Thuột', N'Ea Tu',          N'123 Đường Y Wang'),
(2,  N'Nam Định',       N'Hải Hậu',       N'Hải Lý',         N'Khu 1 Nhà Thờ'),
(3,  N'Tiền Giang',     N'Cái Bè',        N'Đông Hòa Hiệp',  N'Ấp An Lợi'),
(4,  N'Hòa Bình',       N'Mai Châu',      N'Chiềng Châu',    N'Bản Lác'),
(5,  N'Hà Nội',         N'Cầu Giấy',      N'Dịch Vọng',      N'Tòa nhà AgriTower'),
(6,  N'Hồ Chí Minh',   N'Quận 1',        N'Bến Nghé',        N'68 Nguyễn Huệ'),
(7,  N'Đồng Nai',       N'Biên Hòa',      N'Tân Phong',       N'KCN Amata'),
(8,  N'Cần Thơ',        N'Ninh Kiều',     N'An Phú',          N'120 Lý Tự Trọng'),
(9,  N'Đà Nẵng',        N'Hải Châu',      N'Thạch Thang',     N'Trung tâm Hành chính'),
(10, N'Hà Nội',         N'Ba Đình',       N'Quán Thánh',      N'Trụ sở Bộ');

/* =========================================================
   6. FARMS
   ========================================================= */
INSERT INTO iot_Farms (FarmerId, FarmName, Location, AreaHectares, CropType)
VALUES
(1, N'Rẫy Cà Phê Tèo',        '12.6,108.0', 2.5, N'Cà Phê'),
(1, N'Rẫy Tiêu Tèo',          '12.6,108.1', 1.0, N'Hồ Tiêu'),
(2, N'Ruộng Lúa Thắm',        '20.4,106.2', 1.2, N'Lúa Nước'),
(2, N'Vườn Rau Thắm',         '20.4,106.3', 0.5, N'Rau Sạch'),
(3, N'Vườn Sầu Riêng Hùng',   '10.3,106.0', 3.0, N'Sầu Riêng'),
(3, N'Vườn Chôm Chôm',        '10.3,106.1', 1.5, N'Chôm Chôm'),
(4, N'Đồi Cam Hoa',           '20.9,105.1', 1.8, N'Cam Cao Phong'),
(4, N'Vườn Mận Thung Lũng',   '20.9,105.2', 2.0, N'Mận Hậu'),
(1, N'Trại Thủy Canh A',      '12.6,108.2', 0.2, N'Xà Lách'),
(3, N'Vườn Bưởi Da Xanh',     '10.4,106.0', 1.0, N'Bưởi');

/* =========================================================
   7. IOT DEVICES
   ========================================================= */
INSERT INTO iot_IoTDevices (FarmId, DeviceType, Description, BatteryLevel)
VALUES
(1,  'SOIL',    N'Cảm biến độ ẩm đất khu cà phê',       85),
(2,  'AIR',     N'Trạm thời tiết vườn tiêu',             90),
(3,  'WATER',   N'Cảm biến mực nước ruộng lúa',          75),
(4,  'SOIL',    N'Cảm biến dinh dưỡng đất vườn rau',     60),
(5,  'GATEWAY', N'Trạm thu phát Lora trung tâm',         100),
(6,  'AIR',     N'Đo nhiệt ẩm vườn chôm chôm',           95),
(7,  'SOIL',    N'Cảm biến độ ẩm đồi cam',               80),
(8,  'WATER',   N'Cảm biến lưu lượng nước tưới mận',     88),
(9,  'WATER',   N'Đo pH/EC bồn thủy canh',               92),
(10, 'SOIL',    N'Cảm biến gốc bưởi',                    70);

/* =========================================================
   8. SENSOR READINGS
   ========================================================= */
INSERT INTO iot_IoTSensorReadings (DeviceId, MetricType, MetricValue)
VALUES
(1,  'Moisture',       45.5),
(2,  'Temperature',    28.2),
(3,  'WaterLevel',      1.2),
(4,  'PH',              6.5),
(5,  'SignalStrength',  99.0),
(6,  'Humidity',       75.0),
(7,  'Moisture',       50.1),
(8,  'FlowRate',       15.5),
(9,  'EC',              1.8),
(10, 'Temperature',    29.0);

/* =========================================================
   9. FARMING LOGS
   ========================================================= */
INSERT INTO iot_FarmingLogs (FarmId, ActionType, MaterialUsed, Quantity)
VALUES
(1,  N'Bón phân',        N'NPK 16-16-8',        50),
(2,  N'Phun thuốc',      N'Thuốc sinh học',       2),
(3,  N'Tưới nước',       N'Nước giếng khoan',   500),
(4,  N'Thu hoạch',       N'Xà lách',             50),
(5,  N'Cắt tỉa',         NULL,                    0),
(6,  N'Bón lót',         N'Phân chuồng',        200),
(7,  N'Bao trái',        N'Túi lưới',          1000),
(8,  N'Làm cỏ',          NULL,                    0),
(9,  N'Pha dinh dưỡng',  N'Dung dịch A B',       5),
(10, N'Ghi chép',        NULL,                    0);

/* =========================================================
   10. AGRI MACHINES
   ========================================================= */
INSERT INTO logistics_AgriMachines (OwnerId, MachineType, Description, BasePricePerHour)
VALUES
(6, N'Máy Cày Kubota L5018',     N'Máy cày 50HP kèm dàn xới',          250000),
(6, N'Drone Phun Thuốc DJI',     N'Drone tải trọng 40 lít',             800000),
(6, N'Máy Gặt Đập Liên Hợp',    N'Thu hoạch lúa nhanh',                500000),
(8, N'Xe Tải Isuzu 2 Tấn',      N'Xe thùng bạt chở nông sản',          150000),
(6, N'Máy Sấy Vĩ Ngang',        N'Máy sấy lúa 4 tấn/mẻ',              100000),
(6, N'Máy Gieo Hạt 8 Hàng',     N'Gieo hạt tự động hóa',               120000),
(8, N'Xe Cẩu 1 Tấn',            N'Cẩu vật tư',                         300000),
(6, N'Máy Xới Đất Đa Năng',     N'Xới luống động cơ xăng',              80000),
(8, N'Xe Tải Hino 5 Tấn',       N'Chở hàng đường dài',                 250000),
(6, N'Hệ Thống Tưới Cuộn',      N'Ống cuộn tưới 200m',                  70000);

/* =========================================================
   11. MACHINE BOOKINGS
   ========================================================= */
INSERT INTO logistics_MachineBookings
    (MachineId, FarmId, BookerId, StartTime, EndTime, TotalPrice, Status)
VALUES
(2,  1, 1, '2026-04-20 07:00', '2026-04-20 09:00', 1600000, 'BOOKED'),
(3,  3, 2, '2026-04-25 08:00', '2026-04-25 12:00', 2000000, 'COMPLETED'),
(4,  5, 3, '2026-04-26 09:00', '2026-04-26 13:00',  600000, 'COMPLETED'),
(8,  7, 4, '2026-04-10 08:00', '2026-04-10 10:00',  160000, 'CANCELLED'),
(10, 2, 1, '2026-04-18 16:00', '2026-04-18 18:00',  140000, 'BOOKED'),
(9,  6, 3, '2026-04-15 15:00', '2026-04-16 15:00', 6000000, 'IN_PROGRESS'),
(1,  4, 2, '2026-05-10 06:00', '2026-05-10 10:00', 1000000, 'BOOKED'),
(7,  8, 4, '2026-05-12 08:00', '2026-05-12 10:00',  600000, 'BOOKED'),
(5,  9, 1, '2026-04-22 07:00', '2026-04-22 15:00',  800000, 'COMPLETED'),
(6, 10, 3, '2026-04-05 06:00', '2026-04-05 10:00',  480000, 'COMPLETED');

/* =========================================================
   12. PRODUCTS
   ========================================================= */
INSERT INTO commerce_Products (SellerId, Title, Description, Category, Price, Unit)
VALUES
(1, N'Cà Phê Nhân Robusta',  N'Cà phê xanh sàng 18',          N'Nông sản',  65000, N'kg'),
(2, N'Gạo Tám Thơm',         N'Gạo Nam Định',                  N'Nông sản',  22000, N'kg'),
(3, N'Sầu Riêng Ri6',        N'Sầu riêng Tiền Giang',          N'Trái cây', 150000, N'hộp'),
(4, N'Cam Cao Phong',         N'Cam Hòa Bình',                  N'Trái cây',  40000, N'kg'),
(7, N'Phân NPK Đầu Trâu',    N'Bao 25kg',                      N'Vật tư',   450000, N'bao'),
(5, N'Dưa Lưới Taki',        N'Trồng nhà màng',                N'Trái cây',  85000, N'trái'),
(1, N'Hạt Tiêu Đen',         N'Tiêu sấy khô',                  N'Nông sản', 120000, N'kg'),
(5, N'Rau Xà Lách',          N'Thủy canh sạch',                N'Nông sản',  35000, N'kg'),
(3, N'Bưởi Da Xanh',         N'Bưởi ruột hồng',                N'Trái cây',  60000, N'trái'),
(7, N'Chế Phẩm Sinh Học',    N'Trị nấm cây trồng',             N'Vật tư',   120000, N'chai');

/* =========================================================
   13. CARTS
   ========================================================= */
INSERT INTO commerce_Carts (UserId) VALUES (1),(2),(3),(4),(5),(6),(7),(8),(9),(10);

/* =========================================================
   14. CART ITEMS
   ========================================================= */
INSERT INTO commerce_CartItems (CartId, ProductId, Quantity) VALUES
(1,  5,  2),
(2,  1,  5),
(3,  2,  20),
(4,  3,  1),
(5,  4,  5),
(6,  9,  10),
(7,  10, 2),
(8,  6,  4),
(9,  7,  2),
(10, 8,  3);

/* =========================================================
   15. ORDERS
   ========================================================= */
INSERT INTO commerce_Orders (BuyerId, OrderTotal, Status) VALUES
(3,  545000, 'COMPLETED'),
(1,  900000, 'PAID'),
(2,  325000, 'SHIPPING'),
(4,  150000, 'COMPLETED'),
(5,  200000, 'CREATED'),
(6,  380000, 'PAID'),
(7,  500000, 'COMPLETED'),
(8,  340000, 'SHIPPING'),
(9,  650000, 'COMPLETED'),
(10, 150000, 'CANCELLED');

/* =========================================================
   16. ORDER ITEMS
   ========================================================= */
INSERT INTO commerce_OrderItems (OrderId, ProductId, Quantity, Price) VALUES
(1, 1,  5,  65000),
(1, 2,  10, 22000),
(2, 5,  2,  450000),
(3, 1,  5,  65000),
(4, 3,  1,  150000),
(5, 4,  5,  40000),
(6, 9,  10, 38000),
(7, 10, 2,  250000),
(8, 6,  4,  85000),
(9, 1,  10, 65000);

/* =========================================================
   17. NOTIFICATIONS
   ========================================================= */
INSERT INTO Notifications (UserId, Title, IsRead) VALUES
(1,  N'Đơn mua phân bón của bạn đã thanh toán',  1),
(2,  N'Độ ẩm ruộng lúa đang thấp',               0),
(6,  N'Có yêu cầu thuê máy mới',                 0),
(3,  N'Đơn hàng #1 đã giao thành công',           1),
(4,  N'Chuyên gia đã phản hồi câu hỏi',           0),
(8,  N'Máy gặt sẽ đến vào 01/05',                 1),
(8,  N'Tài xế nhận cuốc xe tải thành công',       1),
(1,  N'Pin trạm Lora Farm 1 sắp hết',             0),
(6,  N'Thanh toán đơn #6 thành công',             1),
(9,  N'Có 5 người dùng mới cần duyệt',            0);

/* =========================================================
   18A. PRODUCT IMAGES (mỗi sản phẩm 3 hình)
   ========================================================= */
INSERT INTO Images (ReferenceId, ReferenceType, ImageUrl, IsPrimary, DisplayOrder) VALUES
(1,'PRODUCT','https://picsum.photos/id/101/400/400',1,1),
(1,'PRODUCT','https://picsum.photos/id/102/400/400',0,2),
(1,'PRODUCT','https://picsum.photos/id/103/400/400',0,3),
(2,'PRODUCT','https://picsum.photos/id/104/400/400',1,1),
(2,'PRODUCT','https://picsum.photos/id/106/400/400',0,2),
(2,'PRODUCT','https://picsum.photos/id/107/400/400',0,3),
(3,'PRODUCT','https://picsum.photos/id/108/400/400',1,1),
(3,'PRODUCT','https://picsum.photos/id/109/400/400',0,2),
(3,'PRODUCT','https://picsum.photos/id/110/400/400',0,3),
(4,'PRODUCT','https://picsum.photos/id/111/400/400',1,1),
(4,'PRODUCT','https://picsum.photos/id/112/400/400',0,2),
(4,'PRODUCT','https://picsum.photos/id/113/400/400',0,3),
(5,'PRODUCT','https://picsum.photos/id/114/400/400',1,1),
(5,'PRODUCT','https://picsum.photos/id/115/400/400',0,2),
(5,'PRODUCT','https://picsum.photos/id/116/400/400',0,3),
(6,'PRODUCT','https://picsum.photos/id/117/400/400',1,1),
(6,'PRODUCT','https://picsum.photos/id/118/400/400',0,2),
(6,'PRODUCT','https://picsum.photos/id/119/400/400',0,3),
(7,'PRODUCT','https://picsum.photos/id/120/400/400',1,1),
(7,'PRODUCT','https://picsum.photos/id/121/400/400',0,2),
(7,'PRODUCT','https://picsum.photos/id/122/400/400',0,3),
(8,'PRODUCT','https://picsum.photos/id/123/400/400',1,1),
(8,'PRODUCT','https://picsum.photos/id/124/400/400',0,2),
(8,'PRODUCT','https://picsum.photos/id/125/400/400',0,3),
(9,'PRODUCT','https://picsum.photos/id/126/400/400',1,1),
(9,'PRODUCT','https://picsum.photos/id/127/400/400',0,2),
(9,'PRODUCT','https://picsum.photos/id/128/400/400',0,3),
(10,'PRODUCT','https://picsum.photos/id/129/400/400',1,1),
(10,'PRODUCT','https://picsum.photos/id/130/400/400',0,2),
(10,'PRODUCT','https://picsum.photos/id/131/400/400',0,3);

/* =========================================================
   18B. USER / SME IMAGES
   ========================================================= */
INSERT INTO Images (ReferenceId, ReferenceType, ImageUrl, IsPrimary) VALUES
(1,'USER','https://i.pravatar.cc/150?u=1',1),
(2,'USER','https://i.pravatar.cc/150?u=2',1),
(3,'USER','https://i.pravatar.cc/150?u=3',1),
(4,'USER','https://i.pravatar.cc/150?u=4',1),
(5,'SME','https://picsum.photos/id/205/200/200',1),
(6,'SME','https://picsum.photos/id/206/200/200',1),
(7,'SME','https://picsum.photos/id/207/200/200',1),
(8,'SME','https://picsum.photos/id/208/200/200',1),
(9,'USER','https://i.pravatar.cc/150?u=9',1),
(10,'USER','https://i.pravatar.cc/150?u=10',1);

/* =========================================================
   18C. FARM IMAGES
   ========================================================= */
INSERT INTO Images (ReferenceId, ReferenceType, ImageUrl, IsPrimary) VALUES
(1,'FARM','https://picsum.photos/id/211/600/400',1),
(2,'FARM','https://picsum.photos/id/212/600/400',1),
(3,'FARM','https://picsum.photos/id/213/600/400',1),
(4,'FARM','https://picsum.photos/id/214/600/400',1),
(5,'FARM','https://picsum.photos/id/215/600/400',1),
(6,'FARM','https://picsum.photos/id/216/600/400',1),
(7,'FARM','https://picsum.photos/id/217/600/400',1),
(8,'FARM','https://picsum.photos/id/218/600/400',1),
(9,'FARM','https://picsum.photos/id/219/600/400',1),
(10,'FARM','https://picsum.photos/id/220/600/400',1);

/* =========================================================
   18D. MACHINE IMAGES
   ========================================================= */
INSERT INTO Images (ReferenceId, ReferenceType, ImageUrl, IsPrimary) VALUES
(1,'MACHINE','https://picsum.photos/id/221/500/300',1),
(2,'MACHINE','https://picsum.photos/id/222/500/300',1),
(3,'MACHINE','https://picsum.photos/id/223/500/300',1),
(4,'MACHINE','https://picsum.photos/id/224/500/300',1),
(5,'MACHINE','https://picsum.photos/id/225/500/300',1),
(6,'MACHINE','https://picsum.photos/id/226/500/300',1),
(7,'MACHINE','https://picsum.photos/id/227/500/300',1),
(8,'MACHINE','https://picsum.photos/id/228/500/300',1),
(9,'MACHINE','https://picsum.photos/id/229/500/300',1),
(10,'MACHINE','https://picsum.photos/id/230/500/300',1);
GO
Use prm393

/* =============================================================
   PHẦN III: KIỂM TRA KẾT QUẢ
   ============================================================= */
SELECT
    P.ProductId,
    P.Title,
    P.Price,
    P.Unit,
    U.DisplayName AS SellerName
FROM commerce_Products P
JOIN Users U ON P.SellerId = U.UserId;
GO