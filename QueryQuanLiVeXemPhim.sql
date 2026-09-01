CREATE DATABASE QuanLiBanVeXemPhimDB
go

use QuanLiBanVeXemPhimDB
go

-- 1. Bảng Users
CREATE TABLE Users (
    user_id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    full_name NVARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) DEFAULT 'CUSTOMER' CHECK (role IN ('CUSTOMER', 'STAFF', 'ADMIN')),
    created_at DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET()
);

-- 2. Bảng Movies
CREATE TABLE Movies (
    movie_id INT IDENTITY(1,1) PRIMARY KEY,
    title NVARCHAR(200) NOT NULL,
    description NVARCHAR(MAX),
    duration INT NOT NULL, -- (phút)
    release_date DATE,
    age_rating VARCHAR(10), -- P, K, T13, T16, T18
    poster_url VARCHAR(255),
    status VARCHAR(20) DEFAULT 'NOW_SHOWING' CHECK (status IN ('NOW_SHOWING', 'COMING_SOON', 'END_SHOWING'))
);

-- 3. Bảng Rooms
CREATE TABLE Rooms (
    room_id INT IDENTITY(1,1) PRIMARY KEY,
    room_name NVARCHAR(50) NOT NULL, -- VD: Phòng 01, Phòng IMAX
    total_seats INT NOT NULL
);

-- 4. Bảng Seats
CREATE TABLE Seats (
    seat_id INT IDENTITY(1,1) PRIMARY KEY,
    room_id INT NOT NULL,
    seat_row VARCHAR(2) NOT NULL, -- Hàng A, B, C...
    seat_number INT NOT NULL,    -- Số 1, 2, 3...
    seat_type VARCHAR(20) DEFAULT 'STANDARD' CHECK (seat_type IN ('STANDARD', 'VIP', 'SWEETBOX')),
    CONSTRAINT FK_Seats_Rooms FOREIGN KEY (room_id) REFERENCES Rooms(room_id) ON DELETE CASCADE,
    CONSTRAINT UQ_Room_Seat UNIQUE (room_id, seat_row, seat_number)
);

-- 5. Bảng Showtimes
CREATE TABLE Showtimes (
    showtime_id INT IDENTITY(1,1) PRIMARY KEY,
    movie_id INT NOT NULL,
    room_id INT NOT NULL,
    start_time DATETIMEOFFSET NOT NULL,
    end_time DATETIMEOFFSET NOT NULL,
    base_price DECIMAL(10, 2) NOT NULL,
    CONSTRAINT FK_Showtimes_Movies FOREIGN KEY (movie_id) REFERENCES Movies(movie_id),
    CONSTRAINT FK_Showtimes_Rooms FOREIGN KEY (room_id) REFERENCES Rooms(room_id)
);

-- 6. Bảng Orders
CREATE TABLE Orders (
    order_id VARCHAR(50) PRIMARY KEY, -- VD: 'ORD-20260901-88A9'
    user_id UNIQUEIDENTIFIER NOT NULL,
    total_amount DECIMAL(10, 2) NOT NULL,
    status VARCHAR(20) DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'PAID', 'CANCELLED', 'EXPIRED')),
    created_at DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET(),
    expire_at DATETIMEOFFSET NOT NULL,
    CONSTRAINT FK_Orders_Users FOREIGN KEY (user_id) REFERENCES Users(user_id)
);

-- 7. Bảng Tickets
CREATE TABLE Tickets (
    ticket_id INT IDENTITY(1,1) PRIMARY KEY,
    order_id VARCHAR(50) NOT NULL,
    showtime_id INT NOT NULL,
    seat_id INT NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    qr_code VARCHAR(255) UNIQUE NOT NULL,
    is_checked_in BIT DEFAULT 0,          -- (0: Chưa, 1: Rồi)
    checked_in_at DATETIMEOFFSET NULL,
    CONSTRAINT FK_Tickets_Orders FOREIGN KEY (order_id) REFERENCES Orders(order_id) ON DELETE CASCADE,
    CONSTRAINT FK_Tickets_Showtimes FOREIGN KEY (showtime_id) REFERENCES Showtimes(showtime_id),
    CONSTRAINT FK_Tickets_Seats FOREIGN KEY (seat_id) REFERENCES Seats(seat_id),
    CONSTRAINT UQ_Showtime_Seat UNIQUE (showtime_id, seat_id) -- 1 ghế/suất chiếu chỉ có 1 vé
);


-- 8. Bảng MovieReviews
CREATE TABLE MovieReviews (
    review_id INT IDENTITY(1,1) PRIMARY KEY,
    movie_id INT NOT NULL,
    user_id UNIQUEIDENTIFIER NOT NULL,
    rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5), -- Chấm điểm 1-5 sao
    comment NVARCHAR(MAX) NULL,
    created_at DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET(),
    CONSTRAINT FK_Reviews_Movies FOREIGN KEY (movie_id) REFERENCES Movies(movie_id) ON DELETE CASCADE,
    CONSTRAINT FK_Reviews_Users FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE,
    CONSTRAINT UQ_User_Movie_Review UNIQUE (user_id, movie_id) -- Mỗi user chỉ đánh giá 1 phim 1 lần
);
go
CREATE VIEW View_MovieScore AS
SELECT m.movie_id, m.title, m.poster_url, m.age_rating, m.status, 
        COALESCE(AVG(CAST(r.rating AS FLOAT)), 0) AS avg_rating, COUNT(r.review_id) AS total_reviews
FROM Movies m
LEFT JOIN MovieReviews r ON m.movie_id = r.movie_id
GROUP BY m.movie_id, m.title, m.poster_url, m.age_rating, m.status;