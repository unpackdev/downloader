// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0;

uint8 constant MAX_META = 16;
uint8 constant MAX_ATTRS = 40;
uint8 constant MAX_LAST_ERRORS = 50;
uint16 constant MAX_SLOTS_PRINT = 50;
uint256 constant MAX_STREAMS = 24; // Must be less than 64

struct Result {
    // basic
		uint256 seed;
    uint256 tokenId;
		// data
		bool b64Html;
		bool b64Image;
		string imagePrefix;
		string htmlName;
		string htmlPrefix;
    // for metadata
		string name;
		string description;
		string[MAX_META] metaNames;
		string[MAX_META] metaValues;
    string[MAX_ATTRS] attrTraits;
    string[MAX_ATTRS] attrValues;
		// slots used
		uint32 slots;
		// meta
    uint8 meta;
		// attributes
    uint8 attrs;
    // print slots
    uint16 printSlot;
    string[MAX_SLOTS_PRINT] printSlots;
    // last error from makeError
    uint8 errors;
    string[MAX_LAST_ERRORS] lastErrors;
    // streams
    bytes[MAX_STREAMS] streams;
		bytes[MAX_STREAMS] htmlStreams;
}

struct XCallResult {
    string str;
    uint u;
    int i;
}

struct FyrdGyveResult {
	string[] result;
}

