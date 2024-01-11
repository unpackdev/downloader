// SPDX-License-Identifier: MIT

/**
 * @title Avvenire Citizen Data Interface
*/
pragma solidity ^0.8.4;


interface AvvenireCitizenDataInterface {
    // traits are bound to sex for fitting
    enum Sex {NULL, MALE, FEMALE}

    // make an enumerable for trait types (meant to be overridden with traits from individual project)
    enum TraitType {
        NULL,
        BACKGROUND,
        BODY,
        TATTOO,
        EYES,
        MOUTH,
        MASK,
        NECKLACE,
        CLOTHING,
        EARRINGS,
        HAIR,
        EFFECT
    }

    // struct for storing trait data for the citizen (used ONLY in the citizen struct)
    struct Trait {
        uint256 tokenId; // for mapping traits to their tokens
        string uri;
        bool free; // stores if the trait is free from the citizen (defaults to false)
        bool exists; // checks existence (for minting vs transferring)
        Sex sex;
        TraitType traitType;
        uint256 originCitizenId; // for mapping traits to their previous citizen owners
    }

    // struct for storing all the traits
    struct Traits {
        Trait background;
        Trait body;
        Trait tattoo;
        Trait eyes;
        Trait mouth;
        Trait mask;
        Trait necklace;
        Trait clothing;
        Trait earrings;
        Trait hair;
        Trait effect;
    }


    // struct for storing citizens
    struct Citizen {
        uint256 tokenId;
        string uri;
        bool exists; //  checks existence (for minting vs transferring)
        Sex sex;
        Traits traits;
    }
}
