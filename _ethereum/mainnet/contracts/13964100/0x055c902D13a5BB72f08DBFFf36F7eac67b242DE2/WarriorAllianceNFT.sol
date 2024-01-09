// SPDX-License-Identifier: MIT

/**
    IMPORTANT NOTICE:
    This smart contract was written and deployed by the software engineers at 
    https://highstack.co in a contractor capacity.
    
    Highstack is not responsible for any malicious use or losses arising from using 
    or interacting with this smart contract.

    THIS CONTRACT IS PROVIDED ON AN “AS IS” BASIS. USE THIS SOFTWARE AT YOUR OWN RISK.
    THERE IS NO WARRANTY, EXPRESSED OR IMPLIED, THAT DESCRIBED FUNCTIONALITY WILL 
    FUNCTION AS EXPECTED OR INTENDED. PRODUCT MAY CEASE TO EXIST. NOT AN INVESTMENT, 
    SECURITY OR A SWAP. TOKENS HAVE NO RIGHTS, USES, PURPOSE, ATTRIBUTES, 
    FUNCTIONALITIES OR FEATURES, EXPRESS OR IMPLIED, INCLUDING, WITHOUT LIMITATION, ANY
    USES, PURPOSE OR ATTRIBUTES. TOKENS MAY HAVE NO VALUE. PRODUCT MAY CONTAIN BUGS AND
    SERIOUS BREACHES IN THE SECURITY THAT MAY RESULT IN LOSS OF YOUR ASSETS OR THEIR 
    IMPLIED VALUE. ALL THE CRYPTOCURRENCY TRANSFERRED TO THIS SMART CONTRACT MAY BE LOST.
    THE CONTRACT DEVLOPERS ARE NOT RESPONSIBLE FOR ANY MONETARY LOSS, PROFIT LOSS OR ANY
    OTHER LOSSES DUE TO USE OF DESCRIBED PRODUCT. CHANGES COULD BE MADE BEFORE AND AFTER
    THE RELEASE OF THE PRODUCT. NO PRIOR NOTICE MAY BE GIVEN. ALL TRANSACTION ON THE 
    BLOCKCHAIN ARE FINAL, NO REFUND, COMPENSATION OR REIMBURSEMENT POSSIBLE. YOU MAY 
    LOOSE ALL THE CRYPTOCURRENCY USED TO INTERACT WITH THIS CONTRACT. IT IS YOUR 
    RESPONSIBILITY TO REVIEW THE PROJECT, TEAM, TERMS & CONDITIONS BEFORE USING THE 
    PRODUCT.

**/

pragma solidity ^0.8.4;

import "./ControlledAccess.sol";
import "./ERC721Enumerable.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./ECDSA.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract WarriorAllianceNFT is
    ERC721Enumerable,
    Ownable,
    ReentrancyGuard,
    ControlledAccess
{
    using ECDSA for bytes32;
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using Strings for *;

    address private distributionWallet;

    uint256 public whitelistStart = 1641672000; // Sat Jan 8th 3pm Eastern
    uint256 public publicStart = 1641844800; // Monday Jan 10th 3pm Eastern
    uint256 public maxPrivateWalletHoldings = 3; // max wallet holdings

    string private EMPTY_STRING = "";

    uint256 public MAX_ELEMENTS = 500;
    uint256 public PRICE = 0.3 ether;

    uint256 public maxMint = 3;

    address payable devAddress;
    uint256 private devFee;

    bool private PAUSE = true;

    Counters.Counter private _tokenIdTracker;

    struct BaseTokenUriById {
        uint256 startId;
        uint256 endId;
        string baseURI;
    }

    BaseTokenUriById[] public baseTokenUris;

    event PauseEvent(bool pause);
    event welcomeToKingShiba(uint256 indexed id);

    modifier saleIsOpen() {
        require(totalSupply() <= MAX_ELEMENTS, "Soldout!");
        require(!PAUSE, "Sales not open");
        _;
    }

    constructor(
        address _distributionWallet,
        string memory name,
        string memory ticker
    ) ERC721(name, ticker) {
        distributionWallet = _distributionWallet;
        _mintAmount(20, distributionWallet);
    }

    function setMaxElements(uint256 maxElements) public onlyOwner {
        require(MAX_ELEMENTS < maxElements, "Cannot decrease max elements");
        MAX_ELEMENTS = maxElements;
    }

    function setMintPrice(uint256 mintPriceWei) public onlyOwner {
        PRICE = mintPriceWei;
    }

    function setDevAddress(address _devAddress, uint256 _devFee)
        public
        onlyOwner
    {
        devAddress = payable(_devAddress);
        devFee = _devFee;
    }

    function clearBaseUris() public onlyOwner {
        delete baseTokenUris;
    }

    function setStartTimes(uint256 _whitelistStart, uint256 _publicStart)
        public
        onlyOwner
    {
        publicStart = _publicStart;
        whitelistStart = _whitelistStart;
    }

    function setMaxPrivateWalletHoldings(uint256 max) public onlyOwner {
        maxPrivateWalletHoldings = max;
    }

    function setBaseURI(
        string memory baseURI,
        uint256 startId,
        uint256 endId
    ) public onlyOwner {
        require(
            keccak256(bytes(tokenURI(startId))) ==
                keccak256(bytes(EMPTY_STRING)),
            "Start ID Overlap"
        );
        require(
            keccak256(bytes(tokenURI(endId))) == keccak256(bytes(EMPTY_STRING)),
            "End ID Overlap"
        );

        baseTokenUris.push(
            BaseTokenUriById({startId: startId, endId: endId, baseURI: baseURI})
        );
    }

    function setPause(bool _pause) public onlyOwner {
        PAUSE = _pause;
        emit PauseEvent(PAUSE);
    }

    function setMaxMint(uint256 limit) public onlyOwner {
        maxMint = limit;
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _withdraw(devAddress, balance.mul(devFee).div(100));
        _withdraw(owner(), address(this).balance);
    }

    function mintUnsoldTokens(uint256 amount) public onlyOwner {
        require(PAUSE, "Pause is disable");
        _mintAmount(amount, owner());
    }

    /**
     * @notice Public Mint.
     */
    function mint(uint256 _amount) public payable saleIsOpen nonReentrant {
        require(block.timestamp > publicStart, "Public not open yet.");
        uint256 total = totalSupply();
        require(_amount <= maxMint, "Max limit");
        require(total + _amount <= MAX_ELEMENTS, "Max limit");
        require(msg.value >= price(_amount), "Value below price");
        address wallet = _msgSender();
        _mintAmount(_amount, wallet);
    }

    /**
     * @notice Whitelist Mint.
     */
    function whitelistMint(
        uint256 _amount,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public payable onlyValidAccess(_v, _r, _s) nonReentrant {
        uint256 total = totalSupply();
        address wallet = _msgSender();
        require(block.timestamp > whitelistStart, "Whitelist not open yet.");
        require(
            balanceOf(_msgSender()).add(_amount) <= maxPrivateWalletHoldings,
            "Wallet limit reached"
        );
        require(_amount <= maxMint, "Max limit");
        require(total + _amount <= MAX_ELEMENTS, "Max limit");
        require(msg.value >= price(_amount), "Value below price");

        _mintAmount(_amount, wallet);
    }

    function getUnsoldTokens(uint256 offset, uint256 limit)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory tokens = new uint256[](limit);
        for (uint256 i = 0; i < limit; i++) {
            uint256 key = i + offset;
            if (rawOwnerOf(key) == address(0)) {
                tokens[i] = key;
            }
        }
        return tokens;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        uint256 length = baseTokenUris.length;
        for (uint256 interval = 0; interval < length; ++interval) {
            BaseTokenUriById storage baseTokenUri = baseTokenUris[interval];
            if (
                baseTokenUri.startId <= tokenId && baseTokenUri.endId >= tokenId
            ) {
                return
                    string(
                        abi.encodePacked(
                            baseTokenUri.baseURI,
                            tokenId.toString(),
                            ".json"
                        )
                    );
            }
        }
        return "";
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIdTracker.current();
    }

    function price(uint256 _count) public view returns (uint256) {
        return PRICE.mul(_count);
    }

    function _mintAmount(uint256 amount, address wallet) private {
        for (uint8 i = 0; i < amount; i++) {
            while (
                !(rawOwnerOf(_tokenIdTracker.current().add(1)) == address(0))
            ) {
                _tokenIdTracker.increment();
            }
            _mintAnElement(wallet);
        }
    }

    function _mintAnElement(address _to) private {
        _tokenIdTracker.increment();
        _safeMint(_to, _tokenIdTracker.current());
        emit welcomeToKingShiba(_tokenIdTracker.current());
    }

    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }
}
