// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./ReentrancyGuard.sol";


abstract contract CryptoSkullsContract {
    function ownerOf(uint256 tokenId) public view virtual returns (address);
    function balanceOf(address account) public view virtual returns (uint256);
}

abstract contract DemonsBloodContract {
    function balanceOf(address account, uint256 tokenId) public view virtual returns (uint256);
    function burnForAddress(uint256 typeId, address burnTokenAddress, uint256 amount) external virtual;
}

contract DemonicSkulls is ERC721Enumerable, Ownable, ReentrancyGuard {
    CryptoSkullsContract private cryptoSkullsContract;
    DemonsBloodContract private demonsBloodContract;

    uint256 public levelTwoMintedAmount;
    uint256 public levelThreeMintedAmount;

    uint256 public maxMintsPerTxn = 5;

    uint256 public levelTwoMintPrice = 0.7 ether;
    uint256 public levelThreeMintPrice = 1.5 ether;

    bool public saleIsActive = false;
    bool public claimIsActive = false;

    string public baseURI;

    uint256 public levelTwoIndex = 9999;
    uint256 public levelThreeIndex = 12499;

    address public withdrawalWallet;

    mapping (uint256 => bool) public claimedTokens;
    mapping (address => uint256) public levelTwoClaimers;
    mapping (address => uint256) public levelThreeClaimers;
    mapping (uint256 => bool) public lordsIds;

    uint256 private constant COMMON_BLOOD_TYPE = 0;
    uint256 private constant LORD_BLOOD_TYPE = 1;

    uint256 private constant LEVEL_ONE_BLOOD_AMOUNT = 1;
    uint256 private constant LEVEL_TWO_BLOOD_AMOUNT = 3;
    uint256 private constant LEVEL_THREE_BLOOD_AMOUNT = 5;
    uint256 private constant LORD_BLOOD_AMOUNT = 1;

    event PaymentReleased(address to, uint256 amount);

    constructor(string memory name,
        string memory symbol,
        string memory _baseUri,
        address skullsContract,
        address bloodsContract) ERC721(name, symbol) {
        baseURI = _baseUri;

        cryptoSkullsContract = CryptoSkullsContract(skullsContract);
        demonsBloodContract = DemonsBloodContract(bloodsContract);

        lordsIds[9] = true;
        lordsIds[19] = true;
        lordsIds[20] = true;
        lordsIds[24] = true;
        lordsIds[27] = true;
        lordsIds[36] = true;
        lordsIds[41] = true;
        lordsIds[42] = true;
        lordsIds[43] = true;
        lordsIds[70] = true;
    }

    function setWithdrawalWallet(address wallet) public onlyOwner {
        withdrawalWallet = wallet;
    }

    function setMaxMintsPerTxn(uint256 amount) public onlyOwner {
        maxMintsPerTxn = amount;
    }

    function setLevelTwoMintPrice(uint256 price) public onlyOwner {
        levelTwoMintPrice = price;
    }

    function setLevelThreeMintPrice(uint256 price) public onlyOwner {
        levelThreeMintPrice = price;
    }

    function withdraw(uint256 amount) public onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance");
        require(payable(withdrawalWallet).send(amount));

        emit PaymentReleased(withdrawalWallet, amount);
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function flipClaimState() public onlyOwner {
        claimIsActive = !claimIsActive;
    }

    function claimLords(uint256[] memory ids) public {
        require(claimIsActive, "Claiming must be active");
        require(demonsBloodContract.balanceOf(msg.sender, LORD_BLOOD_TYPE) >= ids.length, "You do not have enough Blood");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];

            require(lordsIds[id], "You can only claim Lord");
            require(!claimedTokens[id], "This Lord had already been claimed");
            require(cryptoSkullsContract.ownerOf(id) == msg.sender, "You must own original Lord");

            claimedTokens[id] = true;
            demonsBloodContract.burnForAddress(LORD_BLOOD_TYPE, msg.sender, LORD_BLOOD_AMOUNT);

            _safeMint(msg.sender, id);
        }
    }

    function claimSkulls(uint256[] memory ids, uint256 bloodAmount) public {
        require(claimIsActive, "Claiming must be active");
        require(bloodAmount == LEVEL_ONE_BLOOD_AMOUNT || bloodAmount == LEVEL_TWO_BLOOD_AMOUNT || bloodAmount == LEVEL_THREE_BLOOD_AMOUNT,
            "Blood amount is incorrect");
        require(demonsBloodContract.balanceOf(msg.sender, COMMON_BLOOD_TYPE) >= bloodAmount * ids.length, "You do not have enough Blood");

        if (bloodAmount == LEVEL_TWO_BLOOD_AMOUNT) {
            require((ids.length + levelTwoClaimers[msg.sender]) <= 50, "You can't mint more than 50 Level 2 Demonic Skulls per wallet");
        } else if (bloodAmount == LEVEL_THREE_BLOOD_AMOUNT) {
            require((ids.length + levelThreeClaimers[msg.sender]) <= 5, "You can't mint more than 5 Level 3 Demonic Skulls per wallet");
        }

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];

            require(!lordsIds[id], "You must use another method to claim Lord");
            require(!claimedTokens[id], "This Demonic Skull had already been claimed");
            require(cryptoSkullsContract.ownerOf(id) == msg.sender, "You must own original CryptoSkull");

            claimedTokens[id] = true;

            if (bloodAmount == LEVEL_ONE_BLOOD_AMOUNT) {
                demonsBloodContract.burnForAddress(COMMON_BLOOD_TYPE, msg.sender, LEVEL_ONE_BLOOD_AMOUNT);

                _safeMint(msg.sender, id);
            } else if (bloodAmount == LEVEL_TWO_BLOOD_AMOUNT) {
                levelTwoClaimers[msg.sender] += 1;
                levelTwoMintedAmount++;

                demonsBloodContract.burnForAddress(COMMON_BLOOD_TYPE, msg.sender, LEVEL_TWO_BLOOD_AMOUNT);

                _safeMint(msg.sender, ++levelTwoIndex);
            } else if (bloodAmount == LEVEL_THREE_BLOOD_AMOUNT) {
                levelThreeClaimers[msg.sender] += 1;
                levelThreeMintedAmount++;

                demonsBloodContract.burnForAddress(COMMON_BLOOD_TYPE, msg.sender, LEVEL_THREE_BLOOD_AMOUNT);

                _safeMint(msg.sender, ++levelThreeIndex);
            }
        }
    }

    function mint(uint256 numberOfTokens, uint256 bloodAmount) public payable {
        require(saleIsActive, "Sale must be active");
        require(numberOfTokens <= maxMintsPerTxn, "You can not mint that many at a time");
        require(bloodAmount == LEVEL_TWO_BLOOD_AMOUNT || bloodAmount == LEVEL_THREE_BLOOD_AMOUNT,
            "You can only mint Level 2 or Level 3 Demonic Skulls");

        uint256 baseMintPrice;

        if (bloodAmount == LEVEL_TWO_BLOOD_AMOUNT) {
            require(levelTwoMintedAmount + numberOfTokens <= 2500, "Purchase would exceed max limit");
            require((numberOfTokens + levelTwoClaimers[msg.sender]) <= 50, "You can't mint more than 50 Level 2 Demonic Skulls per wallet");

            baseMintPrice = levelTwoMintPrice;
        } else if (bloodAmount == LEVEL_THREE_BLOOD_AMOUNT) {
            require(levelThreeMintedAmount + numberOfTokens <= 150, "Purchase would exceed max limit");
            require((numberOfTokens + levelThreeClaimers[msg.sender]) <= 5, "You can't mint more than 5 Level 3 Demonic Skulls per wallet");

            baseMintPrice = levelThreeMintPrice;
        }

        bool hasOriginalSkulls = cryptoSkullsContract.balanceOf(msg.sender) > 0;
        uint256 totalPrice = hasOriginalSkulls ? (baseMintPrice * numberOfTokens) * 80 / 100 : baseMintPrice * numberOfTokens;

        require(totalPrice <= msg.value, "ETH value sent is not correct");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex;

            if (bloodAmount == LEVEL_TWO_BLOOD_AMOUNT) {
                mintIndex = ++levelTwoIndex;

                levelTwoClaimers[msg.sender] += 1;
                levelTwoMintedAmount++;
            } else if (bloodAmount == LEVEL_THREE_BLOOD_AMOUNT) {
                mintIndex = ++levelThreeIndex;

                levelThreeClaimers[msg.sender] += 1;
                levelThreeMintedAmount++;
            }

            _safeMint(msg.sender, mintIndex);
        }
    }


    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }
}
