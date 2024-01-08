pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT

import "./ERC721EnumerableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./IRandomlyAssignedUpgradeable.sol";

contract TycoonUpgradeable is ERC721EnumerableUpgradeable, OwnableUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    IRandomlyAssignedUpgradeable public RandomlyAssignedContract;

    // uint256 public currentSupply;
    uint256 public maxMintAmount;
    uint256 public cost;
    uint256 public preSalesStart; //timestamp
    uint256 public preSalesEnd; //timestamp
    uint256 public publicSalesEnd; //timestamp
    uint256 public revealDelay; //hours
    uint256 public soldOutTime; //timestamp
    uint256 public maxSupply;
    uint256 public maxNFTperUser;

    string private _baseTokenURI;
    string private _notRevealedURI;

    mapping(address => bool) public whitelisted;
    mapping(address => bool) private withdrawers;

    event Withdraw(address to, uint256 amount);

    modifier onlyWithdrawer() {
        require(
            withdrawers[_msgSender()] == true || owner() == _msgSender(),
            "Caller is not the withdrawer"
        );
        _;
    }

    function initialize(
        address RandomlyAssignedAdress,
        string memory name,
        string memory symbol,
        string memory baseTokenURI,
        string memory notRevealedURI,
        uint256 preSalesStart_,
        uint256 preSalesEnd_,
        uint256 publicSalesEnd_,
        uint256 revealDelay_,
        uint256 maxNFTperUser_
    ) public initializer {
        __TycoonUpgradeable_init(
            RandomlyAssignedAdress,
            name,
            symbol,
            baseTokenURI,
            notRevealedURI,
            preSalesStart_,
            preSalesEnd_,
            publicSalesEnd_,
            revealDelay_,
            maxNFTperUser_
        );
    }

    function __TycoonUpgradeable_init(
        address RandomlyAssignedAdress,
        string memory name,
        string memory symbol,
        string memory baseTokenURI,
        string memory notRevealedURI,
        uint256 preSalesStart_,
        uint256 preSalesEnd_,
        uint256 publicSalesEnd_,
        uint256 revealDelay_,
        uint256 maxNFTperUser_
    ) internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained(name, symbol);
        __ERC721Enumerable_init_unchained();
        __TycoonUpgradeable_init_unchained(
            RandomlyAssignedAdress,
            baseTokenURI,
            notRevealedURI,
            preSalesStart_,
            preSalesEnd_,
            publicSalesEnd_,
            revealDelay_,
            maxNFTperUser_
        );
    }

    function __TycoonUpgradeable_init_unchained(
        address RandomlyAssignedAdress,
        string memory baseTokenURI,
        string memory notRevealedURI,
        uint256 preSalesStart_,
        uint256 preSalesEnd_,
        uint256 publicSalesEnd_,
        uint256 revealDelay_,
        uint256 maxNFTperUser_
    ) internal initializer {
        RandomlyAssignedContract = IRandomlyAssignedUpgradeable(
            RandomlyAssignedAdress
        );
        maxMintAmount = 5;
        cost = 0.06 ether;

        _baseTokenURI = baseTokenURI;
        _notRevealedURI = notRevealedURI;
        revealDelay = revealDelay_;
        preSalesStart = preSalesStart_;
        preSalesEnd = preSalesEnd_;
        publicSalesEnd = publicSalesEnd_;
        maxSupply = RandomlyAssignedContract.getMaxSupply();
        maxNFTperUser = maxNFTperUser_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function mint(address to, uint256 mintAmount) public payable {
        require(mintAmount > 0, "Amount of minting must be greater than 0");
        require(
            mintAmount <= maxMintAmount,
            string(
                abi.encodePacked(
                    "Cannot mint more than ",
                    maxMintAmount.toString(),
                    " NFTs"
                )
            )
        );
        require(
            balanceOf(to) + mintAmount <= maxNFTperUser,
            "The balance of the address reaches the limit"
        );

        require(
            totalSupply() + mintAmount <=
                RandomlyAssignedContract.getMaxSupply(),
            "YOU CAN'T MINT MORE THAN MAXIMUM SUPPLY"
        );

        require(
            block.timestamp >= preSalesStart,
            "The PreSales haven't started yet"
        );
        require(block.timestamp <= publicSalesEnd, "The PublicSales has ended");
        if (
            block.timestamp >= preSalesStart && block.timestamp <= preSalesEnd
        ) {
            //PreSales Period
            require(whitelisted[_msgSender()], "YOU ARE NOT ON WHITE LIST");
        }

        if (_msgSender() != owner()) {
            require(msg.value >= cost * mintAmount, "NOT ENOUGH ETHER");
        }

        for (uint256 i = 0; i < mintAmount; i++) {
            uint256 tokenId = RandomlyAssignedContract.nextTokenId();
            _safeMint(to, tokenId);
        }

        //set SoldOut
        if (totalSupply() == RandomlyAssignedContract.getMaxSupply()) {
            soldOutTime = block.timestamp;
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistant token"
        );
        if (isRevealed() == false) {
            return _notRevealedURI;
        }
        return
            bytes(_baseURI()).length > 0
                ? string(
                    abi.encodePacked(_baseURI(), tokenId.toString(), ".json")
                )
                : "";
    }

    function setCost(uint256 newCost) public onlyOwner {
        cost = newCost;
    }

    function setNotRevealedURI(string memory newURI) public onlyOwner {
        _notRevealedURI = newURI;
    }

    function setMaxMinAmount(uint256 newMaxMinAmount) public onlyOwner {
        maxMintAmount = newMaxMinAmount;
    }

    function setPreSalesStart(uint256 newPreSalesStart) public onlyOwner {
        preSalesStart = newPreSalesStart;
    }

    function setPreSalesEnd(uint256 newPreSalesEnd) public onlyOwner {
        preSalesEnd = newPreSalesEnd;
    }

    function setPublicSalesEnd(uint256 newPublicSalesEnd) public onlyOwner {
        publicSalesEnd = newPublicSalesEnd;
    }

    function setRevealDelay(uint256 newRevealDelay) public onlyOwner {
        revealDelay = newRevealDelay;
    }

    function setBaseTokenURI(string memory newBaseTokenURI) public onlyOwner {
        _baseTokenURI = newBaseTokenURI;
    }

    function addWhitelist(address user) public onlyOwner {
        whitelisted[user] = true;
    }

    function massAddingWhitelist(address[] calldata users) public onlyOwner {
        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            whitelisted[user] = true;
        }
    }

    function removeWhitelist(address user) public onlyOwner {
        whitelisted[user] = false;
    }

    function addWithdrawer(address user) public onlyOwner {
        withdrawers[user] = true;
    }

    function withdraw() public payable onlyWithdrawer {
        uint256 contractBalance = address(this).balance;
        require(payable(_msgSender()).send(contractBalance));
        emit Withdraw(_msgSender(), contractBalance);
    }

    function getTimestamp() public view returns (uint256) {
        return block.timestamp;
    }

    function isRevealed() public view returns (bool) {
        uint256 revealAfterSoldOut;
        uint256 revealAfterPublicSales;
        uint256 revealTime;
        revealAfterPublicSales = publicSalesEnd + revealDelay;
        if (soldOutTime != 0) {
            revealAfterSoldOut = soldOutTime + revealDelay;
        }
        if (revealAfterSoldOut != 0) {
            if (revealAfterSoldOut > revealAfterPublicSales) {
                revealTime = revealAfterPublicSales;
            } else {
                revealTime = revealAfterSoldOut;
            }
        } else {
            revealTime = revealAfterPublicSales;
        }
        return block.timestamp >= revealTime;
    }

    function setMaxNFTperUser(uint256 _newMaxNFTperUser) public onlyOwner {
        maxNFTperUser = _newMaxNFTperUser;
    }
}
