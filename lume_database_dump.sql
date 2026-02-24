CREATE DATABASE  IF NOT EXISTS `student_wallet` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;
USE `student_wallet`;
-- MySQL dump 10.13  Distrib 8.0.44, for Win64 (x86_64)
--
-- Host: localhost    Database: student_wallet
-- ------------------------------------------------------
-- Server version	8.0.44

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `card_transactions`
--

DROP TABLE IF EXISTS `card_transactions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `card_transactions` (
  `id` int NOT NULL AUTO_INCREMENT,
  `reg_id` int NOT NULL,
  `card_id` int NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `merchant_name` varchar(255) DEFAULT NULL,
  `txn_type` varchar(50) DEFAULT NULL,
  `status` varchar(20) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `merchant_category` varchar(50) DEFAULT NULL,
  `merchant_reference` varchar(100) DEFAULT NULL,
  `payment_source` varchar(50) DEFAULT NULL,
  `transaction_reference` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `reg_id` (`reg_id`),
  KEY `card_id` (`card_id`),
  CONSTRAINT `card_transactions_ibfk_1` FOREIGN KEY (`reg_id`) REFERENCES `registered_students` (`id`),
  CONSTRAINT `card_transactions_ibfk_2` FOREIGN KEY (`card_id`) REFERENCES `lume_cards` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `card_transactions`
--

LOCK TABLES `card_transactions` WRITE;
/*!40000 ALTER TABLE `card_transactions` DISABLE KEYS */;
/*!40000 ALTER TABLE `card_transactions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `cashback_ledger`
--

DROP TABLE IF EXISTS `cashback_ledger`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `cashback_ledger` (
  `id` int NOT NULL AUTO_INCREMENT,
  `reg_id` int NOT NULL,
  `txn_id` int NOT NULL,
  `amount` decimal(10,2) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cashback_ledger`
--

LOCK TABLES `cashback_ledger` WRITE;
/*!40000 ALTER TABLE `cashback_ledger` DISABLE KEYS */;
INSERT INTO `cashback_ledger` VALUES (5,16,87,6.60,'2026-02-11 17:35:12'),(6,21,88,6.60,'2026-02-11 17:59:03'),(7,16,91,0.60,'2026-02-12 12:35:40'),(8,22,96,3.60,'2026-02-12 16:51:38'),(9,22,97,30.00,'2026-02-12 18:32:32'),(10,22,98,6.60,'2026-02-12 18:32:38'),(11,16,101,0.98,'2026-02-12 18:55:58'),(12,16,102,0.01,'2026-02-12 18:56:37'),(13,16,110,0.60,'2026-02-14 08:23:09'),(14,16,113,0.05,'2026-02-16 05:02:36'),(15,16,114,0.60,'2026-02-16 08:27:56'),(16,17,116,1.17,'2026-02-16 09:01:02');
/*!40000 ALTER TABLE `cashback_ledger` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `lume_cards`
--

DROP TABLE IF EXISTS `lume_cards`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `lume_cards` (
  `id` int NOT NULL AUTO_INCREMENT,
  `reg_id` int NOT NULL,
  `card_number` varchar(32) NOT NULL,
  `card_last4` varchar(4) NOT NULL,
  `expiry_month` int NOT NULL,
  `expiry_year` int NOT NULL,
  `cvv` varchar(10) NOT NULL,
  `card_status` enum('pending','active','blocked','expired') DEFAULT 'active',
  `is_locked` tinyint(1) DEFAULT '0',
  `is_blocked` tinyint(1) DEFAULT '0',
  `daily_limit` decimal(12,2) DEFAULT '50000.00',
  `monthly_limit` decimal(12,2) DEFAULT '300000.00',
  `issued_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `tap_pay_enabled` tinyint(1) DEFAULT '0',
  `ncmc_enabled` tinyint(1) DEFAULT '0',
  `pos_enabled` tinyint(1) DEFAULT '1',
  `online_enabled` tinyint(1) DEFAULT '1',
  `contactless_enabled` tinyint(1) DEFAULT '0',
  `tokenised_enabled` tinyint(1) DEFAULT '1',
  `pos_limit` int DEFAULT '100000',
  `online_limit` int DEFAULT '100000',
  `contactless_limit` int DEFAULT '5000',
  `tokenised_limit` int DEFAULT '100000',
  PRIMARY KEY (`id`),
  UNIQUE KEY `reg_id` (`reg_id`),
  CONSTRAINT `lume_cards_ibfk_1` FOREIGN KEY (`reg_id`) REFERENCES `registered_students` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `lume_cards`
--

LOCK TABLES `lume_cards` WRITE;
/*!40000 ALTER TABLE `lume_cards` DISABLE KEYS */;
INSERT INTO `lume_cards` VALUES (4,16,'5312344666598902','8902',2,2031,'559','active',0,0,50000.00,300000.00,'2026-02-17 22:42:41',1,1,1,1,1,1,50000,44000,5000,100000);
/*!40000 ALTER TABLE `lume_cards` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `notifications`
--

DROP TABLE IF EXISTS `notifications`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `notifications` (
  `id` int NOT NULL AUTO_INCREMENT,
  `reg_id` int NOT NULL,
  `title` varchar(100) NOT NULL,
  `message` varchar(255) NOT NULL,
  `type` enum('reward','reward_earned','card_spend','system','card_security') DEFAULT NULL,
  `amount` decimal(10,2) DEFAULT NULL,
  `is_read` tinyint(1) DEFAULT '0',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `body` text,
  `ref_id` int DEFAULT NULL,
  `is_deleted` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `reg_id` (`reg_id`),
  KEY `is_read` (`is_read`)
) ENGINE=InnoDB AUTO_INCREMENT=202 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `notifications`
--

LOCK TABLES `notifications` WRITE;
/*!40000 ALTER TABLE `notifications` DISABLE KEYS */;
INSERT INTO `notifications` VALUES (1,21,'Split Request','You have a split request of ₹100.00','system',100.00,0,'2026-02-10 14:04:02',NULL,1,0),(2,17,'Split Request','You have a split request of ₹100.00','system',100.00,0,'2026-02-10 14:04:02',NULL,1,0),(3,19,'Split Request','You have a split request of ₹700.00','system',700.00,0,'2026-02-10 14:04:02',NULL,1,0),(4,17,'Split Request','You have a split request of ₹200.00','system',200.00,0,'2026-02-10 15:43:28',NULL,1,0),(5,19,'Split Request','You have a split request of ₹200.00','system',200.00,0,'2026-02-10 15:43:28',NULL,1,0),(6,21,'Split Request','You have a split request of ₹200.00','system',200.00,0,'2026-02-10 15:43:28',NULL,1,0),(7,20,'Split Request','You have a split request of ₹200.00','system',200.00,0,'2026-02-10 15:43:28',NULL,1,0),(8,20,'Split Request','You have a split request of ₹400.00','system',400.00,0,'2026-02-10 15:44:58',NULL,1,0),(9,21,'Split Request','You have a split request of ₹100.00','system',100.00,1,'2026-02-10 15:44:58',NULL,1,0),(10,17,'Split Request','You have a split request of ₹200.00','system',200.00,0,'2026-02-10 15:44:58',NULL,1,0),(11,19,'Split Request','You have a split request of ₹200.00','system',200.00,0,'2026-02-10 15:44:58',NULL,1,0),(12,20,'Split Request','You have a split request of ₹333.34','system',333.34,1,'2026-02-10 15:46:40',NULL,1,0),(14,17,'Split Request','You have a split request of ₹222.22','system',222.22,1,'2026-02-10 15:46:40',NULL,1,0),(16,17,'Split Request','You have a split request of ₹51.00','system',51.00,1,'2026-02-10 17:45:04',NULL,2,0),(17,16,'Split Request','You have a split request of ₹10.00','system',10.00,1,'2026-02-10 17:46:15',NULL,3,0),(18,17,'Split Request','You have a split request of ₹6.00','system',6.00,1,'2026-02-11 06:50:16',NULL,4,0),(20,21,'Cashback Received','₹6.60 cashback added to your wallet','reward',6.60,1,'2026-02-11 17:59:03',NULL,88,0),(21,16,'Coupon Unlocked ?','You received coupon CPN11454','reward',NULL,1,'2026-02-11 18:19:01',NULL,89,0),(22,16,'Voucher Unlocked','You received voucher VCH78499','reward',NULL,1,'2026-02-11 18:46:07',NULL,90,0),(23,16,'Cashback Received','₹0.60 cashback added to your wallet','reward',0.60,1,'2026-02-12 12:35:40',NULL,91,0),(24,21,'Coupon Unlocked ?','You received coupon CPN36265','reward',NULL,0,'2026-02-12 12:59:28',NULL,92,0),(25,19,'Coupon Unlocked ?','You received coupon CPN38848','reward',NULL,0,'2026-02-12 13:16:16',NULL,93,0),(27,22,'Coupon Unlocked ?','You received coupon CPN22873','reward',NULL,1,'2026-02-12 17:45:11',NULL,94,0),(28,22,'Cashback Received','₹30.00 cashback added to your wallet','reward',30.00,0,'2026-02-12 18:32:32',NULL,97,0),(29,22,'Cashback Received','₹6.60 cashback added to your wallet','reward',6.60,0,'2026-02-12 18:32:38',NULL,98,0),(30,22,'Coupon Unlocked ?','You received coupon CPN39187','reward',NULL,0,'2026-02-12 18:48:19',NULL,99,0),(37,16,'Reward Earned ?','You earned a reward. Reveal now!','reward_earned',100.00,1,'2026-02-14 08:23:50',NULL,111,0),(38,16,'Coupon Unlocked ?','You received coupon CPN10525','reward',NULL,1,'2026-02-14 08:23:56',NULL,111,0),(39,16,'Reward Earned ?','You earned a reward. Reveal now!','reward_earned',40.00,1,'2026-02-14 08:51:56',NULL,112,0),(41,16,'Card Security Update','Your card ending with 1785 has been locked.','card_security',NULL,1,'2026-02-14 09:24:00',NULL,NULL,0),(43,16,'Coupon Unlocked ?','You received coupon CPN15674','reward',NULL,1,'2026-02-14 09:24:48',NULL,112,0),(46,17,'Card Security Update','Your card ending with 6377 has been locked.','card_security',NULL,1,'2026-02-14 09:57:29',NULL,NULL,0),(47,17,'Card Security Update','Your card ending with 6377 has been unlocked.','card_security',NULL,1,'2026-02-14 09:57:34',NULL,NULL,0),(49,17,'Card Security Update','Your card ending with 6377 has been locked.','card_security',NULL,0,'2026-02-14 10:05:32',NULL,NULL,0),(50,17,'Card Security Update','Your card ending with 6377 has been unlocked.','card_security',NULL,0,'2026-02-14 10:05:38',NULL,NULL,0),(51,16,'Card Security Update','Your card ending with 1785 has been unlocked.','card_security',NULL,0,'2026-02-14 10:12:11',NULL,NULL,0),(52,16,'Card Security Update','Your card ending with 1785 has been locked.','card_security',NULL,0,'2026-02-14 10:12:18',NULL,NULL,0),(53,16,'Reward Earned ?','You earned a reward. Reveal now!','reward_earned',10.00,1,'2026-02-16 05:02:33',NULL,113,0),(54,16,'Cashback Received','₹0.05 cashback added to your wallet','reward',0.05,1,'2026-02-16 05:02:36',NULL,113,0),(106,16,'Card Security Update','Your card ending with 1785 has been locked.','card_security',NULL,1,'2026-02-16 06:24:34',NULL,NULL,0),(107,16,'Card Security Update','Your card ending with 1785 has been unlocked.','card_security',NULL,1,'2026-02-16 06:24:59',NULL,NULL,0),(109,16,'Cashback Received','₹0.60 cashback added to your wallet','reward',0.60,1,'2026-02-16 08:27:56',NULL,114,0),(112,16,'Split Request','You have a split request of ₹156.00','system',156.00,1,'2026-02-16 08:58:04',NULL,5,0),(113,17,'Split Request','You have a split request of ₹174.00','system',174.00,0,'2026-02-16 08:58:04',NULL,5,0),(114,16,'Reward Earned ?','You earned a reward. Reveal now!','reward_earned',156.00,1,'2026-02-16 08:59:08',NULL,115,0),(115,16,'Coupon Unlocked ?','You received coupon CPN58783','reward',NULL,1,'2026-02-16 08:59:39',NULL,115,0),(116,17,'Reward Earned ?','You earned a reward. Reveal now!','reward_earned',174.00,0,'2026-02-16 09:00:55',NULL,116,0),(117,17,'Cashback Received','₹1.17 cashback added to your wallet','reward',1.17,0,'2026-02-16 09:01:02',NULL,116,0),(194,16,'Card Blocked','Your card has been permanently blocked.','card_security',NULL,1,'2026-02-17 17:10:17',NULL,NULL,0),(195,16,'Card Replacement Ordered','Your new card will be issued shortly.','card_security',NULL,1,'2026-02-17 17:12:41',NULL,NULL,0),(200,16,'Tap & Pay Enabled','Your card can now be used for contactless payments.','card_security',NULL,1,'2026-02-17 17:43:43',NULL,NULL,0),(201,16,'NCMC Enabled','You can now pay in metro & buses using your card.','card_security',NULL,1,'2026-02-17 17:43:48',NULL,NULL,0);
/*!40000 ALTER TABLE `notifications` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `registered_students`
--

DROP TABLE IF EXISTS `registered_students`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `registered_students` (
  `id` int NOT NULL AUTO_INCREMENT,
  `student_id` int DEFAULT NULL,
  `upi_id` varchar(100) DEFAULT NULL,
  `wallet_status` enum('inactive','active') DEFAULT 'inactive',
  `aadhaar_verified` tinyint(1) DEFAULT '0',
  `pan_verified` tinyint(1) DEFAULT '0',
  `pan_number` varchar(10) DEFAULT NULL,
  `kyc_completion_percent` int DEFAULT '0',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `tier` enum('silver','gold','platinum') DEFAULT 'silver',
  `total_spent` decimal(10,2) DEFAULT '0.00',
  `profile_image` varchar(255) DEFAULT NULL,
  `aadhaar_last4` char(4) DEFAULT NULL,
  `pan_masked` varchar(10) DEFAULT NULL,
  `reward_points` int DEFAULT '0',
  `tier_cycle_start` date DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `student_id` (`student_id`),
  CONSTRAINT `registered_students_ibfk_1` FOREIGN KEY (`student_id`) REFERENCES `students` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=24 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `registered_students`
--

LOCK TABLES `registered_students` WRITE;
/*!40000 ALTER TABLE `registered_students` DISABLE KEYS */;
INSERT INTO `registered_students` VALUES (16,1,'themakkonen@lumepay','active',1,1,NULL,100,'2026-01-13 17:49:14','silver',5044.00,'http://192.168.0.3:5000/uploads\\profile_16_1770738610.jpg','5815','GHSPRXXXXC',81,'2026-01-01'),(17,2,'mayaa@lumepay','inactive',1,0,NULL,75,'2026-01-13 17:49:58','silver',652.22,'http://192.168.0.3:5000/uploads\\profile_17.jpg','5814','GHSPRXXXXM',16,'2026-01-01'),(18,4,'kayaa@lumepay','active',1,0,NULL,75,'2026-01-13 18:44:42','silver',0.00,NULL,NULL,NULL,0,NULL),(19,5,'pussycat@lumepay','active',1,0,NULL,75,'2026-01-23 12:08:22','silver',282.22,NULL,NULL,NULL,7,'2026-01-01'),(20,3,'sama@lumepay','active',1,0,NULL,75,'2026-01-23 12:33:07','silver',333.34,NULL,NULL,NULL,5,'2026-01-01'),(21,6,'jayaa@lumepay','active',1,0,NULL,75,'2026-01-24 04:12:29','silver',2456.11,NULL,NULL,NULL,54,'2026-01-01'),(22,7,'maanu@lumepay','active',1,0,NULL,75,'2026-01-24 06:39:34','silver',3080.00,NULL,NULL,NULL,39,'2026-01-01'),(23,9,NULL,'inactive',0,0,NULL,0,'2026-02-20 09:30:23','silver',0.00,NULL,NULL,NULL,0,'2026-01-01');
/*!40000 ALTER TABLE `registered_students` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `reward_reveals`
--

DROP TABLE IF EXISTS `reward_reveals`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `reward_reveals` (
  `id` int NOT NULL AUTO_INCREMENT,
  `reg_id` int NOT NULL,
  `txn_id` int NOT NULL,
  `reward_type` enum('cashback','coupon','voucher') NOT NULL,
  `reward_value` varchar(100) NOT NULL,
  `status` varchar(20) DEFAULT 'pending',
  `reveal_token` varchar(100) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `reveal_token` (`reveal_token`)
) ENGINE=InnoDB AUTO_INCREMENT=27 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `reward_reveals`
--

LOCK TABLES `reward_reveals` WRITE;
/*!40000 ALTER TABLE `reward_reveals` DISABLE KEYS */;
INSERT INTO `reward_reveals` VALUES (1,16,85,'coupon','CPN55172','revealed','81a2232b-faac-44e3-b473-4e5194cd525a','2026-02-11 17:13:39'),(2,21,86,'cashback','6.6','pending','0f7a60e1-2964-403e-8b34-634923555a6c','2026-02-11 17:24:27'),(3,16,87,'cashback','6.6','revealed','a3a1f5b9-f30c-4e3c-b995-40a9722fdebd','2026-02-11 17:31:24'),(4,21,88,'cashback','6.6','revealed','f3c721ca-1545-40b9-a382-55612023c0e5','2026-02-11 17:58:50'),(5,16,89,'coupon','CPN11454','revealed','a2f41cbf-ef3a-4ed7-96de-d403207c0c21','2026-02-11 18:16:50'),(6,16,90,'voucher','VCH78499','revealed','a2688a2c-cc53-48a1-b5fb-fe7ba4cc418a','2026-02-11 18:45:57'),(7,16,91,'cashback','0.6','revealed','cb4b462e-007c-4012-99c8-acc284aeb7d2','2026-02-12 12:35:12'),(8,21,92,'coupon','CPN36265','revealed','34f4b8f5-bcca-4ad6-99d0-32d3ef7454e5','2026-02-12 12:59:24'),(9,19,93,'coupon','CPN38848','revealed','390efc92-c213-411d-b7ce-aa56a191e9aa','2026-02-12 13:16:11'),(10,22,94,'coupon','CPN22873','revealed','26db05b2-810b-46ee-953f-0bfb3764c4a7','2026-02-12 14:56:56'),(11,22,96,'cashback','3.6','revealed','8dbc3377-c430-4548-82ac-58d1dd82c337','2026-02-12 16:43:50'),(12,22,97,'cashback','30.0','revealed','a46fea15-99c7-43dc-9b85-a8be996a3c20','2026-02-12 17:52:16'),(13,22,98,'cashback','6.6','revealed','7824b20c-9eca-46c0-9b64-5244cc07f404','2026-02-12 18:05:27'),(14,22,99,'coupon','CPN39187','revealed','521aafa9-c402-4fc0-ba81-aacbe76a863e','2026-02-12 18:43:54'),(15,16,100,'coupon','CPN16221','revealed','1fdd6c98-7c8f-48d0-b64a-6ff50f1a3c58','2026-02-12 18:49:15'),(16,16,101,'cashback','0.98','revealed','3e7dd4d3-8f77-4246-afe9-edec1be291e4','2026-02-12 18:55:52'),(17,16,102,'cashback','0.01','revealed','022adc7e-b3d8-4ff3-be96-be037680a433','2026-02-12 18:56:33'),(20,16,110,'cashback','0.6','revealed','631fcd08-e40e-416a-816a-b7b13a415ebe','2026-02-14 08:23:05'),(21,16,111,'coupon','CPN10525','revealed','78fb6ff0-7438-4236-a075-079fde728de9','2026-02-14 08:23:50'),(22,16,112,'coupon','CPN15674','revealed','56446562-58ce-4026-ae4e-1d15d641da37','2026-02-14 08:51:56'),(23,16,113,'cashback','0.05','revealed','68b51121-29b4-4d24-aa5a-f528ed368a6a','2026-02-16 05:02:33'),(24,16,114,'cashback','0.6','revealed','2ed4c818-c65b-4b2a-b969-e96b5e5059c0','2026-02-16 08:27:28'),(25,16,115,'coupon','CPN58783','revealed','436ec166-b11a-4523-a00b-0c403ee95d32','2026-02-16 08:59:08'),(26,17,116,'cashback','1.17','revealed','c44aa59b-31bb-4b4d-8c60-321349ca962d','2026-02-16 09:00:55');
/*!40000 ALTER TABLE `reward_reveals` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `saved_cards`
--

DROP TABLE IF EXISTS `saved_cards`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `saved_cards` (
  `id` int NOT NULL AUTO_INCREMENT,
  `reg_id` int NOT NULL,
  `last4` varchar(4) DEFAULT NULL,
  `card_brand` varchar(20) DEFAULT NULL,
  `card_type` varchar(20) DEFAULT NULL,
  `card_token` varchar(255) DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT '1',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `saved_cards`
--

LOCK TABLES `saved_cards` WRITE;
/*!40000 ALTER TABLE `saved_cards` DISABLE KEYS */;
INSERT INTO `saved_cards` VALUES (9,16,'7522','visa','debit','tok_7522',1,'2026-01-22 07:25:49'),(10,19,'4242','visa','debit','tok_4242',1,'2026-01-23 12:12:32'),(11,16,'2424','visa','debit','tok_2424',1,'2026-01-26 13:31:14'),(12,21,'7522','visa','debit','tok_7522',1,'2026-01-27 16:26:25'),(13,23,'4242','visa','debit','tok_4242',1,'2026-02-20 09:33:06');
/*!40000 ALTER TABLE `saved_cards` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `scholar_applications`
--

DROP TABLE IF EXISTS `scholar_applications`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `scholar_applications` (
  `id` int NOT NULL AUTO_INCREMENT,
  `full_name` varchar(100) DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL,
  `phone` varchar(15) DEFAULT NULL,
  `loan_amount` bigint DEFAULT NULL,
  `city` varchar(100) DEFAULT NULL,
  `country` varchar(50) DEFAULT NULL,
  `admission_status` varchar(50) DEFAULT NULL,
  `target_intake` varchar(10) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `status` enum('pending','completed') DEFAULT 'pending',
  `registered_student_id` int NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_scholar_reg_id` (`registered_student_id`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `scholar_applications`
--

LOCK TABLES `scholar_applications` WRITE;
/*!40000 ALTER TABLE `scholar_applications` DISABLE KEYS */;
INSERT INTO `scholar_applications` VALUES (2,'Harshith Reddy','harshithreddy799@gmail.com','6304268828',100000,'Hyderabad','India','Applied','02/2026','2026-02-03 17:42:56','completed',16),(8,'Sai Teja','harshithreddyrollakanti@gmail.com','6301729290',200000,'Hyderabad','India','Applied','07/2026','2026-02-03 18:33:00','pending',17);
/*!40000 ALTER TABLE `scholar_applications` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `split_groups`
--

DROP TABLE IF EXISTS `split_groups`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `split_groups` (
  `id` int NOT NULL AUTO_INCREMENT,
  `creator_reg_id` int NOT NULL,
  `total_amount` decimal(10,2) NOT NULL,
  `per_person_amount` decimal(10,2) NOT NULL,
  `status` varchar(20) DEFAULT 'pending',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `note` text,
  `split_type` varchar(20) DEFAULT 'EVEN',
  `paid_amount` decimal(10,2) DEFAULT '0.00',
  `closed` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `split_groups`
--

LOCK TABLES `split_groups` WRITE;
/*!40000 ALTER TABLE `split_groups` DISABLE KEYS */;
INSERT INTO `split_groups` VALUES (1,16,1000.00,200.00,'completed','2026-02-10 21:16:40','Pizza','shares',1000.00,1),(2,16,85.00,42.50,'completed','2026-02-10 23:15:04',NULL,'percent',85.00,1),(3,17,100.00,50.00,'completed','2026-02-10 23:16:15',NULL,'exact',100.00,1),(4,16,9.00,4.50,'completed','2026-02-11 12:20:16',NULL,'shares',9.00,1),(5,21,600.00,200.00,'completed','2026-02-16 14:28:04',NULL,'percent',600.00,1);
/*!40000 ALTER TABLE `split_groups` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `split_members`
--

DROP TABLE IF EXISTS `split_members`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `split_members` (
  `id` int NOT NULL AUTO_INCREMENT,
  `split_group_id` int DEFAULT NULL,
  `member_reg_id` int DEFAULT NULL,
  `amount` decimal(10,2) DEFAULT NULL,
  `status` varchar(20) DEFAULT 'pending',
  `paid_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `split_members`
--

LOCK TABLES `split_members` WRITE;
/*!40000 ALTER TABLE `split_members` DISABLE KEYS */;
INSERT INTO `split_members` VALUES (1,1,16,111.11,'paid','2026-02-10 21:16:40'),(2,1,20,333.34,'paid','2026-02-10 21:21:23'),(3,1,21,111.11,'paid','2026-02-10 21:18:23'),(4,1,17,222.22,'paid','2026-02-10 21:19:14'),(5,1,19,222.22,'paid','2026-02-10 21:20:34'),(6,2,16,34.00,'paid','2026-02-10 23:15:05'),(7,2,17,51.00,'paid','2026-02-11 10:33:23'),(8,3,17,90.00,'paid','2026-02-10 23:16:15'),(9,3,16,10.00,'paid','2026-02-10 23:17:09'),(10,4,16,3.00,'paid','2026-02-11 12:20:17'),(11,4,17,6.00,'paid','2026-02-11 12:21:01'),(12,5,21,270.00,'paid','2026-02-16 14:28:04'),(13,5,16,156.00,'paid','2026-02-16 14:29:08'),(14,5,17,174.00,'paid','2026-02-16 14:30:55');
/*!40000 ALTER TABLE `split_members` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `students`
--

DROP TABLE IF EXISTS `students`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `students` (
  `id` int NOT NULL AUTO_INCREMENT,
  `university_id` int DEFAULT NULL,
  `full_name` varchar(255) DEFAULT NULL,
  `dob` date DEFAULT NULL,
  `mobile` varchar(15) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `aadhaar_last4` char(4) DEFAULT NULL,
  `kyc_status` enum('pending','verified','rejected') DEFAULT 'pending',
  `graduation_year` int DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT '1',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `university_student_id` varchar(100) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_university_student_id` (`university_student_id`),
  UNIQUE KEY `unique_university_student` (`university_id`,`university_student_id`),
  UNIQUE KEY `unique_mobile` (`mobile`),
  UNIQUE KEY `unique_email` (`email`),
  UNIQUE KEY `unique_student_mobile` (`mobile`),
  UNIQUE KEY `unique_student_email` (`email`),
  CONSTRAINT `fk_students_university` FOREIGN KEY (`university_id`) REFERENCES `universities` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `students`
--

LOCK TABLES `students` WRITE;
/*!40000 ALTER TABLE `students` DISABLE KEYS */;
INSERT INTO `students` VALUES (1,2,'Rollakanti Harshith Reddy','2004-12-15','6304268828','2211cs020446@mallareddyuniversity.ac.in','5815','verified',2026,1,'2026-01-07 11:41:06','2211CS020446'),(2,2,'Routhu Sai Teja','2004-08-21','6301729290','2211cs020447@mallareddyuniversity.ac.in','5678','pending',2025,1,'2026-01-07 11:41:06','2211CS020447'),(3,2,'Sama Lakshmi Sahithi','2005-09-22','7396139868','2211cs020448@mallareddyuniversity.ac.in','1234','pending',2024,1,'2026-01-07 11:41:06','2211CS020448'),(4,2,'Pulijala Kashyap Karthikeya','2004-09-25','9182723362','2211cs020422@mallareddyuniversity.ac.in','3456','pending',2026,1,'2026-01-07 11:41:06','2211CS020422'),(5,2,'Puligari Shashank Reddy','2004-10-20','9704332084','2211cs020424@mallareddyuniversity.ac.in','6789','pending',2025,1,'2026-01-07 11:41:06','2211CS020424'),(6,2,'Perala Sai Jayavardhan','2004-11-16','8333835124','2211cs020412@mallareddyuniversity.ac.in','9876','pending',2026,1,'2026-01-07 03:48:00','2211CS020412'),(7,2,'Pallerla Soumith Kumar','2004-07-20','9392480060','2211cs020390@mallareddyuniversity.ac.in','1011','pending',2026,1,'2026-01-07 03:50:30','2211CS020390'),(8,2,'Rishu Thakur','2004-08-22','9100328417','2211cs020445@mallareddyuniversity.ac.in','8897','pending',2026,1,'2026-02-16 03:50:30','2211CS020445'),(9,1,'Ravi Kumar Kurupudi','1989-07-01','9059458849','2021ba01@mahindrauniversity.edu.in','1122','pending',2028,1,'2026-02-16 03:50:30','2021ba01');
/*!40000 ALTER TABLE `students` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `transactions`
--

DROP TABLE IF EXISTS `transactions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `transactions` (
  `id` int NOT NULL AUTO_INCREMENT,
  `wallet_id` int DEFAULT NULL,
  `amount` decimal(10,2) DEFAULT NULL,
  `txn_type` enum('credit','debit') DEFAULT NULL,
  `source` enum('oncampus','upi') DEFAULT NULL,
  `status` enum('success','failed','pending') DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `transactions`
--

LOCK TABLES `transactions` WRITE;
/*!40000 ALTER TABLE `transactions` DISABLE KEYS */;
/*!40000 ALTER TABLE `transactions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `universities`
--

DROP TABLE IF EXISTS `universities`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `universities` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `domain` varchar(100) DEFAULT NULL,
  `status` enum('active','inactive') DEFAULT 'active',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `universities`
--

LOCK TABLES `universities` WRITE;
/*!40000 ALTER TABLE `universities` DISABLE KEYS */;
INSERT INTO `universities` VALUES (1,'Mahindra University','mahindrauniversity.edu.in','active'),(2,'Malla Reddy University','mallareddyuniversity.ac.in','active'),(3,'Malla Reddy Engineering College','mrec.ac.in','active'),(4,'SRM University','srmist.edu.in','active'),(5,'St.Peters Engineering college','spechyd.ac.in','active');
/*!40000 ALTER TABLE `universities` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user_coupons`
--

DROP TABLE IF EXISTS `user_coupons`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_coupons` (
  `id` int NOT NULL AUTO_INCREMENT,
  `reg_id` int NOT NULL,
  `coupon_code` varchar(50) DEFAULT NULL,
  `txn_id` int DEFAULT NULL,
  `status` varchar(20) DEFAULT 'active',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_coupons`
--

LOCK TABLES `user_coupons` WRITE;
/*!40000 ALTER TABLE `user_coupons` DISABLE KEYS */;
INSERT INTO `user_coupons` VALUES (1,16,'CPN11454',89,'active','2026-02-11 18:19:01'),(2,21,'CPN36265',92,'active','2026-02-12 12:59:28'),(3,19,'CPN38848',93,'active','2026-02-12 13:16:16'),(4,22,'CPN22873',94,'active','2026-02-12 17:45:11'),(5,22,'CPN39187',99,'active','2026-02-12 18:48:19'),(6,16,'CPN16221',100,'active','2026-02-12 18:49:17'),(7,16,'CPN55172',85,'active','2026-02-12 18:50:31'),(8,16,'CPN10525',111,'active','2026-02-14 08:23:56'),(9,16,'CPN15674',112,'active','2026-02-14 09:24:48'),(10,16,'CPN58783',115,'active','2026-02-16 08:59:39');
/*!40000 ALTER TABLE `user_coupons` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user_vouchers`
--

DROP TABLE IF EXISTS `user_vouchers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_vouchers` (
  `id` int NOT NULL AUTO_INCREMENT,
  `reg_id` int NOT NULL,
  `voucher_code` varchar(50) DEFAULT NULL,
  `txn_id` int DEFAULT NULL,
  `status` varchar(20) DEFAULT 'active',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_vouchers`
--

LOCK TABLES `user_vouchers` WRITE;
/*!40000 ALTER TABLE `user_vouchers` DISABLE KEYS */;
INSERT INTO `user_vouchers` VALUES (1,16,'VCH78499',90,'active','2026-02-11 18:46:07');
/*!40000 ALTER TABLE `user_vouchers` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `wallet_security`
--

DROP TABLE IF EXISTS `wallet_security`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `wallet_security` (
  `reg_id` int NOT NULL,
  `wallet_pin_hash` varchar(255) DEFAULT NULL,
  `wallet_pin_attempts` int DEFAULT '0',
  `wallet_pin_locked` tinyint(1) DEFAULT '0',
  `card_pin_hash` varchar(255) DEFAULT NULL,
  `card_pin_attempts` int DEFAULT '0',
  `card_pin_locked` tinyint(1) DEFAULT '0',
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`reg_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `wallet_security`
--

LOCK TABLES `wallet_security` WRITE;
/*!40000 ALTER TABLE `wallet_security` DISABLE KEYS */;
INSERT INTO `wallet_security` VALUES (16,'$2b$12$Z8/phEQgJZvo2qRaftdzDeU4Omymh5yCrcGwQ7rzWaoFO/fONCLfq',0,0,'$2b$12$AeUBfdlvZuHmZG.jXsjWR.tiPIHC/VIGnQhP0i/clRC5RgfgC7kBG',0,0,'2026-02-17 17:37:46'),(17,'$2b$12$PhRXfmkVY/ULbgYa/8dw0e2.YC9nzLVsZn33ib29fDRmyXTfASukO',0,0,'$2b$12$3DdSkDlfprk.0Vpkr0Uw1..msBmJ7sYvAE2V0c/rOhsdOZaa7Al0K',0,0,'2026-02-14 09:57:22'),(18,'$2b$12$X9s9VwxgNgGWGkXiD0ebRejU7sE6QxXxAe9ZPakXvlykavyjgvCLG',0,0,NULL,0,0,'2026-01-13 18:46:25'),(19,'$2b$12$nYaD/hRqaw3rqqs3j12twOcq92w5MLIBazfntzWRGsHNd/.Jd.aLK',0,0,NULL,0,0,'2026-02-12 13:16:11'),(20,'$2b$12$4OX1Socwjt5hI8sc11Eqh.NACIarudxjPfmfjuj1H8HUD0HATNY6a',0,0,NULL,0,0,'2026-01-23 13:07:16'),(21,'$2b$12$ldzsR0Z609WJvXfneaHU.OLF31gdOorD/sAEtPyM3YO0CQd9UIHF6',0,0,NULL,0,0,'2026-02-11 17:24:26'),(22,'$2b$12$4EYyTSKfawP4XHlPjFZQiuCXwkFq5ZAsaOPA9i6fmyk5c9HK5/Sei',0,0,NULL,0,0,'2026-02-12 18:43:53');
/*!40000 ALTER TABLE `wallet_security` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `wallet_transactions`
--

DROP TABLE IF EXISTS `wallet_transactions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `wallet_transactions` (
  `id` int NOT NULL AUTO_INCREMENT,
  `sender_reg_id` int NOT NULL,
  `receiver_reg_id` int DEFAULT NULL,
  `amount` decimal(10,2) NOT NULL,
  `type` enum('wallet') DEFAULT 'wallet',
  `status` enum('pending','success','failed') NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `failure_reason` varchar(255) DEFAULT NULL,
  `txn_type` enum('transfer','add_money','upi','upi_payment','spend') DEFAULT NULL,
  `receiver_upi_id` varchar(255) DEFAULT NULL,
  `counterparty_name` varchar(100) DEFAULT NULL,
  `payment_method` varchar(20) DEFAULT NULL,
  `payment_ref` varchar(100) DEFAULT NULL,
  `card_id` int DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=120 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `wallet_transactions`
--

LOCK TABLES `wallet_transactions` WRITE;
/*!40000 ALTER TABLE `wallet_transactions` DISABLE KEYS */;
INSERT INTO `wallet_transactions` VALUES (1,16,NULL,2.00,'wallet','success','2026-01-27 10:36:01',NULL,'upi','nandakumar8121122-2@okicici','Nanda Kumar','upi',NULL,NULL),(2,16,17,2.00,'wallet','success','2026-01-27 10:50:24',NULL,'transfer','mayaa@lumepay','Routhu Sai Teja','wallet',NULL,NULL),(3,16,17,2.00,'wallet','success','2026-01-27 11:01:18',NULL,'transfer','mayaa@lumepay','Routhu Sai Teja','wallet',NULL,NULL),(4,17,NULL,20.00,'wallet','success','2026-01-27 11:31:43',NULL,'upi','themakkonen@lumepay','Rollakanti Harshith Reddy','upi',NULL,NULL),(5,17,16,2.00,'wallet','success','2026-01-27 11:33:36',NULL,'transfer','themakkonen@lumepay','Rollakanti Harshith Reddy','wallet',NULL,NULL),(6,17,16,10.00,'wallet','success','2026-01-27 11:39:47',NULL,'transfer','themakkonen@lumepay','Rollakanti Harshith Reddy','wallet',NULL,NULL),(7,17,16,1.00,'wallet','success','2026-01-27 13:05:07',NULL,'transfer','themakkonen@lumepay','Rollakanti Harshith Reddy','wallet',NULL,NULL),(8,21,21,20.00,'wallet','success','2026-01-27 16:25:10',NULL,'add_money',NULL,NULL,'card',NULL,NULL),(9,21,17,280.00,'wallet','success','2026-01-27 16:29:52',NULL,'transfer','mayaa@lumepay','Routhu Sai Teja','wallet',NULL,NULL),(10,21,NULL,10.00,'wallet','success','2026-01-27 16:32:45',NULL,'upi','nandakumar8121122-2@okicici','Nanda Kumar','upi',NULL,NULL),(11,21,16,10.00,'wallet','success','2026-01-27 17:05:44',NULL,'transfer','themakkonen@lumepay','Rollakanti Harshith Reddy','wallet',NULL,NULL),(12,16,NULL,1.00,'wallet','success','2026-01-27 17:27:21',NULL,'upi','nandakumar8121122-2@okicici','Nanda Kumar','upi',NULL,NULL),(13,16,NULL,10.00,'wallet','success','2026-01-27 17:32:49',NULL,'upi','nandakumar8121122-2@okicici','Nanda Kumar','upi',NULL,NULL),(14,21,16,1.00,'wallet','success','2026-01-28 12:37:39',NULL,'transfer','themakkonen@lumepay','Rollakanti Harshith Reddy','wallet',NULL,NULL),(15,21,NULL,4.00,'wallet','success','2026-01-28 12:47:16',NULL,'upi','nandakumar8121122-2@okicici','Nanda Kumar','upi',NULL,NULL),(16,16,NULL,0.50,'wallet','success','2026-01-28 18:12:05',NULL,'upi','nandakumar8121122-2@okicici','Nanda Kumar','upi',NULL,NULL),(17,16,20,0.50,'wallet','success','2026-01-28 18:12:51',NULL,'transfer','sama@lumepay','Sama Lakshmi Sahithi','wallet',NULL,NULL),(18,16,17,200.00,'wallet','success','2026-01-31 11:20:54',NULL,'transfer','mayaa@lumepay','Routhu Sai Teja','wallet',NULL,NULL),(19,16,18,20.00,'wallet','success','2026-02-01 14:23:36',NULL,'transfer','kayaa@lumepay','Pulijala Kashyap Karthikeya','wallet',NULL,NULL),(20,16,22,20.00,'wallet','success','2026-02-02 11:59:30',NULL,'transfer','maanu@lumepay','Pallerla Soumith Kumar','wallet',NULL,NULL),(21,16,NULL,10.00,'wallet','success','2026-02-02 12:21:02',NULL,'upi','nandakumar8121122-2@okicici','Nanda Kumar','upi',NULL,NULL),(22,17,16,11.00,'wallet','success','2026-02-02 12:26:32',NULL,'transfer','themakkonen@lumepay','Rollakanti Harshith Reddy','wallet',NULL,NULL),(23,16,17,1.00,'wallet','success','2026-02-02 12:32:06',NULL,'transfer','mayaa@lumepay','Routhu Sai Teja','wallet',NULL,NULL),(24,16,18,10.00,'wallet','success','2026-02-02 12:39:44',NULL,'transfer','kayaa@lumepay','Pulijala Kashyap Karthikeya','wallet',NULL,NULL),(25,17,16,100.00,'wallet','success','2026-02-02 12:45:40',NULL,'transfer','themakkonen@lumepay','Rollakanti Harshith Reddy','wallet',NULL,NULL),(26,16,17,20.00,'wallet','success','2026-02-02 13:02:33',NULL,'transfer','mayaa@lumepay','Routhu Sai Teja','wallet',NULL,NULL),(27,16,17,10.00,'wallet','success','2026-02-02 13:05:28',NULL,'transfer','mayaa@lumepay','Routhu Sai Teja','wallet',NULL,NULL),(28,17,16,20.00,'wallet','success','2026-02-02 13:16:36',NULL,'transfer','themakkonen@lumepay','Rollakanti Harshith Reddy','wallet',NULL,NULL),(29,16,17,1.00,'wallet','success','2026-02-02 13:37:46',NULL,'transfer','mayaa@lumepay','Routhu Sai Teja','wallet',NULL,NULL),(30,16,17,1.00,'wallet','success','2026-02-02 13:43:25',NULL,'transfer','mayaa@lumepay','Routhu Sai Teja','wallet',NULL,NULL),(31,16,19,1.00,'wallet','success','2026-02-02 13:51:59',NULL,'transfer','pussycat@lumepay','Puligari Shashank Reddy','wallet',NULL,NULL),(32,16,17,1.00,'wallet','success','2026-02-02 15:25:47',NULL,'transfer','mayaa@lumepay','Routhu Sai Teja','wallet',NULL,NULL),(33,16,17,1.00,'wallet','success','2026-02-02 15:32:13',NULL,'transfer','mayaa@lumepay','Routhu Sai Teja','wallet',NULL,NULL),(34,16,16,2000.00,'wallet','success','2026-02-02 15:50:09',NULL,'add_money',NULL,NULL,'card',NULL,11),(35,16,NULL,1000.00,'wallet','success','2026-02-02 15:50:37',NULL,'upi','nandakumar8121122-2@okicici','Nanda Kumar','upi',NULL,NULL),(36,16,17,85.00,'wallet','success','2026-02-02 16:22:41',NULL,'transfer','mayaa@lumepay','Routhu Sai Teja','wallet',NULL,NULL),(37,16,17,5.00,'wallet','success','2026-02-02 17:54:47',NULL,'transfer','mayaa@lumepay','Routhu Sai Teja','wallet',NULL,NULL),(38,16,NULL,20.00,'wallet','success','2026-02-04 04:14:37',NULL,'upi','6301729290@ybl','ROUTHU SAI TEJA','upi',NULL,NULL),(39,17,NULL,5.00,'wallet','success','2026-02-04 17:11:32',NULL,'upi','6304268828@kotak811','R REDDY','upi',NULL,NULL),(40,16,20,1000.00,'wallet','success','2026-02-04 17:20:19',NULL,'transfer','sama@lumepay','Sama Lakshmi Sahithi','wallet',NULL,NULL),(41,16,20,5.00,'wallet','success','2026-02-05 16:30:06',NULL,'transfer','sama@lumepay','Sama Lakshmi Sahithi','wallet',NULL,NULL),(42,16,NULL,10.00,'wallet','success','2026-02-06 16:43:13',NULL,'upi','6301729290@ybl','ROUTHU SAI TEJA','upi',NULL,NULL),(43,16,NULL,20.00,'wallet','success','2026-02-07 05:28:47',NULL,'upi','ravikkurupudi-4@oksbi','Ravi Kumar Kurupudi','upi',NULL,NULL),(44,16,16,5000.00,'wallet','success','2026-02-07 05:32:05',NULL,'add_money',NULL,NULL,'card',NULL,9),(55,16,NULL,15.00,'wallet','success','2026-02-10 07:41:43',NULL,'transfer','split','Split Payment','wallet',NULL,NULL),(56,17,NULL,5.00,'wallet','success','2026-02-10 07:42:15',NULL,'transfer','split','Split Payment','wallet',NULL,NULL),(57,16,NULL,5.00,'wallet','success','2026-02-10 09:30:56',NULL,'upi','ravikkurupudi-4@oksbi','Ravi Kumar Kurupudi','upi',NULL,NULL),(58,21,21,500.00,'wallet','success','2026-02-10 11:37:51',NULL,'add_money',NULL,NULL,'card',NULL,12),(59,21,16,5.00,'wallet','success','2026-02-10 12:09:49',NULL,'transfer','themakkonen@lumepay','Rollakanti Harshith Reddy','wallet',NULL,NULL),(64,21,21,500.00,'wallet','success','2026-02-10 13:26:57',NULL,'add_money',NULL,NULL,'card',NULL,12),(67,21,16,111.11,'wallet','success','2026-02-10 15:48:23',NULL,'transfer','themakkonen@lumepay','Rollakanti Harshith Reddy | Split - Pizza','wallet',NULL,NULL),(68,17,16,222.22,'wallet','success','2026-02-10 15:49:14',NULL,'transfer','themakkonen@lumepay','Rollakanti Harshith Reddy | Split - Pizza','wallet',NULL,NULL),(69,19,16,222.22,'wallet','success','2026-02-10 15:50:34',NULL,'transfer','themakkonen@lumepay','Rollakanti Harshith Reddy | Split - Pizza','wallet',NULL,NULL),(70,20,16,333.34,'wallet','success','2026-02-10 15:51:23',NULL,'transfer','themakkonen@lumepay','Rollakanti Harshith Reddy | Split - Pizza','wallet',NULL,NULL),(71,16,17,10.00,'wallet','success','2026-02-10 17:47:09',NULL,'transfer','mayaa@lumepay','Routhu Sai Teja','wallet',NULL,NULL),(72,17,16,51.00,'wallet','success','2026-02-11 05:03:23',NULL,'transfer','themakkonen@lumepay','Rollakanti Harshith Reddy','wallet',NULL,NULL),(73,16,NULL,5.00,'wallet','success','2026-02-11 06:16:38',NULL,'upi','6304268828@kotak811','R REDDY','upi',NULL,NULL),(74,16,17,9.00,'wallet','success','2026-02-11 06:47:12',NULL,'transfer','mayaa@lumepay','Routhu Sai Teja','wallet',NULL,NULL),(75,17,16,6.00,'wallet','success','2026-02-11 06:51:01',NULL,'transfer','themakkonen@lumepay','Rollakanti Harshith Reddy','wallet',NULL,NULL),(76,16,17,6.00,'wallet','success','2026-02-11 13:29:05',NULL,'transfer','mayaa@lumepay','Routhu Sai Teja','wallet',NULL,NULL),(77,16,NULL,10.00,'wallet','success','2026-02-11 13:39:16',NULL,'upi','ravikkurupudi-4@oksbi','Ravi Kumar Kurupudi','upi',NULL,NULL),(78,17,16,20.00,'wallet','success','2026-02-11 13:45:09',NULL,'transfer','themakkonen@lumepay','Rollakanti Harshith Reddy','wallet',NULL,NULL),(79,16,17,20.00,'wallet','success','2026-02-11 13:46:15',NULL,'transfer','mayaa@lumepay','Routhu Sai Teja','wallet',NULL,NULL),(80,16,17,10.00,'wallet','success','2026-02-11 13:52:22',NULL,'transfer','mayaa@lumepay','Routhu Sai Teja','wallet',NULL,NULL),(81,17,16,10.00,'wallet','success','2026-02-11 14:07:21',NULL,'transfer','themakkonen@lumepay','Rollakanti Harshith Reddy','wallet',NULL,NULL),(82,16,17,10.00,'wallet','success','2026-02-11 14:08:44',NULL,'transfer','mayaa@lumepay','Routhu Sai Teja','wallet',NULL,NULL),(83,16,17,100.00,'wallet','success','2026-02-11 14:12:33',NULL,'transfer','mayaa@lumepay','Routhu Sai Teja','wallet',NULL,NULL),(84,16,21,20.00,'wallet','success','2026-02-11 14:16:13',NULL,'transfer','jayaa@lumepay','Perala Sai Jayavardhan','wallet',NULL,NULL),(85,16,21,600.00,'wallet','success','2026-02-11 17:13:39',NULL,'transfer','jayaa@lumepay','Perala Sai Jayavardhan','wallet',NULL,NULL),(86,21,16,600.00,'wallet','success','2026-02-11 17:24:27',NULL,'transfer','themakkonen@lumepay','Rollakanti Harshith Reddy','wallet',NULL,NULL),(87,16,21,600.00,'wallet','success','2026-02-11 17:31:24',NULL,'transfer','jayaa@lumepay','Perala Sai Jayavardhan','wallet',NULL,NULL),(88,21,16,600.00,'wallet','success','2026-02-11 17:58:50',NULL,'transfer','themakkonen@lumepay','Rollakanti Harshith Reddy','wallet',NULL,NULL),(89,16,21,200.00,'wallet','success','2026-02-11 18:16:50',NULL,'transfer','jayaa@lumepay','Perala Sai Jayavardhan','wallet',NULL,NULL),(90,16,21,7.00,'wallet','success','2026-02-11 18:45:57',NULL,'transfer','jayaa@lumepay','Perala Sai Jayavardhan','wallet',NULL,NULL),(91,16,NULL,100.00,'wallet','success','2026-02-12 12:35:12',NULL,'upi','ravikkurupudi-4@oksbi','Ravi Kumar Kurupudi','upi',NULL,NULL),(92,21,20,40.00,'wallet','success','2026-02-12 12:59:24',NULL,'transfer','sama@lumepay','Sama Lakshmi Sahithi','wallet',NULL,NULL),(93,19,18,60.00,'wallet','success','2026-02-12 13:16:11',NULL,'transfer','kayaa@lumepay','Pulijala Kashyap Karthikeya','wallet',NULL,NULL),(94,22,21,40.00,'wallet','success','2026-02-12 14:56:56',NULL,'transfer','jayaa@lumepay','Perala Sai Jayavardhan','wallet',NULL,NULL),(95,22,22,10000.00,'wallet','success','2026-02-12 15:03:04',NULL,'add_money',NULL,NULL,'card',NULL,NULL),(96,22,19,400.00,'wallet','success','2026-02-12 16:43:50',NULL,'transfer','pussycat@lumepay','Puligari Shashank Reddy','wallet',NULL,NULL),(97,22,21,2000.00,'wallet','success','2026-02-12 17:52:16',NULL,'transfer','jayaa@lumepay','Perala Sai Jayavardhan','wallet',NULL,NULL),(98,22,16,600.00,'wallet','success','2026-02-12 18:05:27',NULL,'transfer','themakkonen@lumepay','Rollakanti Harshith Reddy','wallet',NULL,NULL),(99,22,17,40.00,'wallet','success','2026-02-12 18:43:54',NULL,'transfer','mayaa@lumepay','Routhu Sai Teja','wallet',NULL,NULL),(100,16,22,100.00,'wallet','success','2026-02-12 18:49:15',NULL,'transfer','maanu@lumepay','Pallerla Soumith Kumar','wallet',NULL,NULL),(101,16,22,150.00,'wallet','success','2026-02-12 18:55:52',NULL,'transfer','maanu@lumepay','Pallerla Soumith Kumar','wallet',NULL,NULL),(102,16,21,2.00,'wallet','success','2026-02-12 18:56:33',NULL,'transfer','jayaa@lumepay','Perala Sai Jayavardhan','wallet',NULL,NULL),(103,16,16,50.00,'wallet','success','2026-02-13 08:38:57',NULL,'add_money',NULL,NULL,'card',NULL,11),(104,16,16,100.00,'wallet','success','2026-02-14 05:47:59',NULL,'add_money',NULL,NULL,'card',NULL,9),(105,16,16,1000.00,'wallet','success','2026-02-14 08:03:00',NULL,'add_money',NULL,NULL,'card',NULL,NULL),(106,16,16,50.00,'wallet','success','2026-02-14 08:10:48',NULL,'add_money',NULL,NULL,'card',NULL,NULL),(108,16,NULL,100.00,'wallet','failed','2026-02-14 08:18:02','1265 (01000): Data truncated for column \'type\' at row 1','upi','mayaa@lumepay','Routhu Sai Teja','upi',NULL,NULL),(110,16,17,100.00,'wallet','success','2026-02-14 08:23:05',NULL,'transfer','mayaa@lumepay','Routhu Sai Teja','wallet',NULL,NULL),(111,16,21,100.00,'wallet','success','2026-02-14 08:23:50',NULL,'transfer','jayaa@lumepay','Perala Sai Jayavardhan','wallet',NULL,NULL),(112,16,NULL,40.00,'wallet','success','2026-02-14 08:51:56',NULL,'upi_payment','ravikkurupudi-4@oksbi','Ravi Kumar Kurupudi','upi',NULL,NULL),(113,16,NULL,10.00,'wallet','success','2026-02-16 05:02:33',NULL,'upi_payment','ravikkurupudi-4@oksbi','Ravi Kumar Kurupudi','upi',NULL,NULL),(114,16,NULL,100.00,'wallet','success','2026-02-16 08:27:28',NULL,'upi_payment','ravikkurupudi-4@oksbi','Ravi Kumar Kurupudi','upi',NULL,NULL),(115,16,21,156.00,'wallet','success','2026-02-16 08:59:08',NULL,'transfer','jayaa@lumepay','Perala Sai Jayavardhan','wallet',NULL,NULL),(116,17,21,174.00,'wallet','success','2026-02-16 09:00:55',NULL,'transfer','jayaa@lumepay','Perala Sai Jayavardhan','wallet',NULL,NULL),(117,16,16,500.00,'wallet','failed','2026-02-20 09:22:04','USER_CANCELLED','add_money',NULL,NULL,'card',NULL,NULL),(118,16,16,500.00,'wallet','failed','2026-02-20 09:22:20','AUTO_CANCELLED_TIMEOUT','add_money',NULL,NULL,'card',NULL,NULL);
/*!40000 ALTER TABLE `wallet_transactions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `wallets`
--

DROP TABLE IF EXISTS `wallets`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `wallets` (
  `id` int NOT NULL AUTO_INCREMENT,
  `registered_student_id` int DEFAULT NULL,
  `balance` decimal(10,2) DEFAULT '0.00',
  `status` enum('inactive','active','blocked') DEFAULT 'inactive',
  PRIMARY KEY (`id`),
  KEY `registered_student_id` (`registered_student_id`),
  CONSTRAINT `wallets_ibfk_1` FOREIGN KEY (`registered_student_id`) REFERENCES `registered_students` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `wallets`
--

LOCK TABLES `wallets` WRITE;
/*!40000 ALTER TABLE `wallets` DISABLE KEYS */;
INSERT INTO `wallets` VALUES (1,16,7345.33,'active'),(2,17,707.95,'active'),(3,18,410.00,'active'),(4,19,418.78,'active'),(5,20,892.16,'active'),(6,21,3004.49,'active'),(7,22,7250.20,'active'),(8,23,0.00,'inactive');
/*!40000 ALTER TABLE `wallets` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-02-23 21:25:20
