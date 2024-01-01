//SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

import "./ERC1155URIStorage.sol";

contract BSCD is ERC1155URIStorage {

    string public constant BASE_URI = "https://beige-past-anglerfish-912.mypinata.cloud/ipfs/QmXit2HmS44KJCZt9KT1EoR1NCu9ebhdhfmLsEbNBKjLzf/";

    address _owner;

    string public name = "Bitcoin Currency Denominated Structured Certificate of Deposit";
    string public symbol = "BSCD";

    struct Denomination {
        uint256 id;
        uint256 dollarValue;
        uint256 supply;
    }

    mapping(uint256 => Denomination) denominations;

    constructor() ERC1155(BASE_URI) {
        _setBaseURI(BASE_URI);
        _owner = msg.sender;

        initialize();
    }

    function initialize() internal {
        denominations[1] = Denomination(1, 1, 1000);
        denominations[2] = Denomination(2, 2, 1000);
        denominations[3] = Denomination(3, 5, 200);
        denominations[4] = Denomination(4, 10, 200);
        denominations[5] = Denomination(5, 20, 1000);
        denominations[6] = Denomination(6, 50, 500);
        denominations[7] = Denomination(7, 100, 500);

        _setURI(1, "1.json");
        _mint(_owner, 1, denominations[1].supply, "");
        _setURI(2, "2.json");
        _mint(_owner, 2, denominations[2].supply, "");
        _setURI(3, "3.json");
        _mint(_owner, 3, denominations[3].supply, "");
        _setURI(4, "4.json");
        _mint(_owner, 4, denominations[4].supply, "");
        _setURI(5, "5.json");
        _mint(_owner, 5, denominations[5].supply, "");
        _setURI(6, "6.json");
        _mint(_owner, 6, denominations[6].supply, "");
        _setURI(7, "7.json");
        _mint(_owner, 7, denominations[7].supply, "");
    }

    function customSend(address to, uint256 one, uint256 two, uint256 five, uint256 ten, uint256 twenty, uint256 fifty, uint256 oneHundred) public {
        uint256[7] memory amounts = [one, two, five, ten, twenty, fifty, oneHundred];
        for(uint256 id = 1; id < 8; id++) {
            if(amounts[id-1] > 0 && balanceOf(msg.sender, id) > 0)
                _safeTransferFrom(msg.sender, to, id, amounts[id-1], "");
        }
    }

    function autoSend(address to, uint256 USDamount) external {
        uint256[7] memory amounts;
        uint256 amountToSend = USDamount;
        for(uint256 id = 7; id > 0; id--) {
            if(amountToSend == 0) break;

            if(denominations[id].dollarValue <= amountToSend && balanceOf(msg.sender, id) > 0) {
                amountToSend -= denominations[id].dollarValue;

                amounts[id-1]++;
                id++;
            }
        }

        require(amountToSend == 0, "You do not have enough USD or needed bills");
        customSend(to, amounts[0], amounts[1], amounts[2], amounts[3], amounts[4], amounts[5], amounts[6]);
    }

    modifier onlyOwner {
        require(msg.sender == _owner, "You are not the owner");
        _;
    }
}