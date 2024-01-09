// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library MetaDrinksTypes {
    struct Drink {
        string symbol;
        string nameA;
        string nameB;
        string nameC;
        string alcoBase;
        string alcoBasePostfix;
        string bitterSweet;
        string sourPart;
        bool hasFruitOrHerb;
        string fruitOrHerb;
        string dressing;
        string dressingPostfix;
        string method;
        string glass;
        bool hasGlassPostfix;
        string glassPostfix;
        bool hasTopUp;
        string topUp;
    }
}
