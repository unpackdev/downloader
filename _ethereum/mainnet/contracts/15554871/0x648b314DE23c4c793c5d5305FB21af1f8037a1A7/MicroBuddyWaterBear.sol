//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

// |  \/  (_)              |  _ \          | |   | (_)
// | \  / |_  ___ _ __ ___ | |_) |_   _  __| | __| |_  ___  ___ ™
// | |\/| | |/ __| '__/ _ \|  _ <| | | |/ _` |/ _` | |/ _ \/ __|
// | |  | | | (__| | | (_) | |_) | |_| | (_| | (_| | |  __/\__ \
// |_|  |_|_|\___|_|  \___/|____/ \__,_|\__,_|\__,_|_|\___||___/ 2022
// https://wb.microbuddies.io/

import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC721A.sol";
import "./Strings.sol";

contract MicroBuddyWaterBear is Ownable, Pausable, ERC721A {
    uint256 public WHITE_LIST_START_TIME = 1663527600;
    uint256 public WHITE_LIST_DURATION = 72 * 3600;
    uint256 public GEN0_DURATION = 336 * 3600;
    uint16 public TREASURY_RESERVE = 63;
    uint16 public AIRDROP_RESERVE = 0;
    uint16 public GEN0_RESERVE = 0;
    bool public TREASURY_MINT_DONE = false;
    uint256 public RESTING_PRICE = 0.00069 ether;
    uint16 public MAX_SUPPLY = 5555;
    uint16 public PUBLIC_MINTED;
    uint16 public GEN0_MINTED;
    uint8 public MAX_MINT = 5;
    string public PROVENANCE_RECORD = "";

    bool public REVEALED;
    string public UNREVEALED_URI =
        "https://api.microbuddies.io/unrevealed.json";
    string public AIRDROP_URI =
        "https://api.microbuddies.io/airdrop_unrevealed.json";
    string public BASE_URI;

    mapping(address => int8) public minted;
    mapping(address => uint16) public genZeroList;
    mapping(address => bool) blacklist;

    constructor() ERC721A("MicroBuddy Water Bear", "MBWB") {}

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function addBlacklist(address addr) public onlyOwner {
        require(isContract(addr), "Not a smart contract!");
        blacklist[addr] = true;
    }

    function rmBlacklist(address addr) public onlyOwner {
        blacklist[addr] = false;
    }

    function isBlacklist(address addr) public view returns (bool) {
        return blacklist[addr];
    }

    function isContract(address _addr) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    function setStartTime(uint256 _startTime) public onlyOwner {
        WHITE_LIST_START_TIME = _startTime;
    }

    function mintPublicWL(uint8 quantity) public payable whenNotPaused {
        require(
            block.timestamp >= WHITE_LIST_START_TIME,
            "Public sale not started!"
        );

        require(
            PUBLIC_MINTED +
                GEN0_RESERVE +
                TREASURY_RESERVE +
                AIRDROP_RESERVE +
                quantity <=
                MAX_SUPPLY,
            "Not enough supply!"
        );

        require(
            block.timestamp <= WHITE_LIST_START_TIME + WHITE_LIST_DURATION,
            "Public sale is over!"
        );

        require(msg.value >= (RESTING_PRICE * quantity), "Not enough ETH");

        uint8 remaining = getMintsRemaining(msg.sender);
        require(quantity <= remaining, "Cannot mint this many!");

        PUBLIC_MINTED += quantity;

        if (quantity == remaining) {
            minted[msg.sender] = -1;
        } else {
            minted[msg.sender] += int8(quantity);
        }

        _safeMint(msg.sender, quantity);
    }

    function mintGenZeroWL(uint16 quantity) public payable whenNotPaused {
        require(
            block.timestamp >= WHITE_LIST_START_TIME + WHITE_LIST_DURATION,
            "Public sale not over!"
        );

        require(
            block.timestamp <=
                WHITE_LIST_START_TIME + WHITE_LIST_DURATION + GEN0_DURATION,
            "Gen 0 claim is over!"
        );

        require(GEN0_MINTED + quantity <= GEN0_RESERVE, "Max Gen 0 minted!");
        require(genZeroList[msg.sender] >= quantity, "Over allocation!");

        genZeroList[msg.sender] -= quantity;
        GEN0_MINTED += quantity;
        _safeMint(msg.sender, quantity);
    }

    function airdrop(address[] calldata receivers) public onlyOwner {
        require(
            block.timestamp < WHITE_LIST_START_TIME,
            "Public sale started!"
        );

        for (uint256 i = 0; i < receivers.length; i++) {
            _safeMint(receivers[i], 1);
            AIRDROP_RESERVE++;
        }
    }

    function treasuryMint(address receiver) public onlyOwner {
        require(AIRDROP_RESERVE > 0, "Airdrop not done!");
        require(!TREASURY_MINT_DONE, "Treasury mint is already done!");

        TREASURY_MINT_DONE = true;
        _safeMint(receiver, TREASURY_RESERVE);
    }

    function mintExcessToTreasury(address receiver) public onlyOwner {
        require(
            block.timestamp >
                WHITE_LIST_START_TIME + WHITE_LIST_DURATION + GEN0_DURATION,
            "Sale not over!"
        );

        _safeMint(
            receiver,
            MAX_SUPPLY -
                (PUBLIC_MINTED +
                    GEN0_MINTED +
                    TREASURY_RESERVE +
                    AIRDROP_RESERVE)
        );
    }

    function withdrawFinalFunds() public onlyOwner {
        require(
            block.timestamp >
                WHITE_LIST_START_TIME + WHITE_LIST_DURATION + GEN0_DURATION,
            "Sale not over!"
        );

        uint256 finalFunds = address(this).balance;

        (bool succ, ) = payable(owner()).call{value: finalFunds}("");
        require(succ, "transfer failed");
    }

    function setGenZeroList(
        address[] calldata addresses,
        uint16[] calldata numAllowedToMint
    ) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            genZeroList[addresses[i]] = numAllowedToMint[i];
            GEN0_RESERVE += numAllowedToMint[i];
        }
    }

    function setRevealData(
        bool _revealed,
        string memory _unrevealedURI,
        string memory _airdropURI
    ) public onlyOwner {
        REVEALED = _revealed;
        UNREVEALED_URI = _unrevealedURI;
        AIRDROP_URI = _airdropURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        BASE_URI = baseURI;
    }

    function setWhiteListStartTime(uint256 _whiteListStartTime)
        public
        onlyOwner
    {
        require(
            block.timestamp < WHITE_LIST_START_TIME,
            "Public sale already started!"
        );
        WHITE_LIST_START_TIME = _whiteListStartTime;
    }

    function setGen0Duration(uint256 _gen0Duration) public onlyOwner {
        GEN0_DURATION = _gen0Duration;
    }

    function setWhiteListDuration(uint256 _whiteListDuration) public onlyOwner {
        WHITE_LIST_DURATION = _whiteListDuration;
    }

    function getMintsRemaining(address addr) public view returns (uint8) {
        if (
            PUBLIC_MINTED + GEN0_RESERVE + TREASURY_RESERVE + AIRDROP_RESERVE >=
            MAX_SUPPLY
        ) {
            return 0;
        }

        if (minted[addr] == -1) {
            return 0;
        }

        return MAX_MINT - uint8(minted[addr]);
    }

    function setProvenanceRecord(string calldata record) public onlyOwner {
        require(
            bytes(PROVENANCE_RECORD).length == 0,
            "Provenance already set!"
        );

        PROVENANCE_RECORD = record;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (REVEALED) {
            return
                string(
                    abi.encodePacked(
                        BASE_URI,
                        Strings.toString(_tokenId),
                        ".json"
                    )
                );
        } else {
            if (_tokenId < AIRDROP_RESERVE) {
                return AIRDROP_URI;
            }

            return UNREVEALED_URI;
        }
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override whenNotPaused {
        require(!isBlacklist(msg.sender), "Contract blacklisted");
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override whenNotPaused {
        require(!isBlacklist(msg.sender), "Contract blacklisted");
        super.safeTransferFrom(from, to, tokenId);
    }
}
