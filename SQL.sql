CREATE TABLE `prefech_properties` (
  `id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `display_name` varchar(255) NOT NULL,
  `marker_pos` varchar(255) NOT NULL,
  `forsale_blip` int(3) NOT NULL,
  `sold_blip` int(3) NOT NULL,
  `sign_pos` varchar(255) NOT NULL,
  `sign_heading` varchar(255) NOT NULL,
  `inrange` int(2) NOT NULL,
  `isOwned` varchar(255) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

ALTER TABLE `prefech_properties`
  ADD PRIMARY KEY (`id`);

ALTER TABLE `prefech_properties`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1;
COMMIT;