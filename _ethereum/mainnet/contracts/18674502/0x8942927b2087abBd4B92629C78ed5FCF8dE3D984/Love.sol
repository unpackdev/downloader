// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// This is the love contract for Zoey and Qiwei
contract Love {
    /**
     * Lover contains the name of the lover
     * @param englishName the english name of the lover
     * @param chineseName the chinese name of the lover
     */
    struct Lover {
        string englishName;
        string chineseName;
    }

    struct Location {
        string country;
        string city;
    }

    struct Coordinate {
        // latitude in unit of wei
        uint latitude;
        // longitude in unit of wei
        uint longitude;
    }

    event LoveEvent(
        Lover lover1,
        Lover lover2,
        uint time,
        Location location,
        Coordinate coordinate,
        string message
    );

    event LoveMessage(string message);

    Lover lover1;
    Lover lover2;
    uint startTime;
    Location location;
    Coordinate coordinate;
    string message;

    constructor(string memory _message) {
        // set the lover1
        lover1 = Lover("Zoey Wen", unicode"文一舟");

        // set the lover2
        lover2 = Lover("Qiwei Li", unicode"李其炜");

        // set the love contract effective time
        startTime = block.timestamp;

        message = _message;

        // set the love contract location
        location = Location("China", "Hong Kong");

        // set the love contract location coordinate
        coordinate = Coordinate(22337653383437270000, 114264053356569890000);

        // broadcast the love to the world
        emit LoveEvent(
            lover1,
            lover2,
            startTime,
            location,
            coordinate,
            message
        );

        // broadcast the love message to the world
        emit LoveMessage(message);
    }

    function getDetail()
        public
        view
        returns (
            Lover memory,
            Lover memory,
            uint,
            Location memory,
            Coordinate memory,
            string memory
        )
    {
        return (lover1, lover2, startTime, location, coordinate, message);
    }
}