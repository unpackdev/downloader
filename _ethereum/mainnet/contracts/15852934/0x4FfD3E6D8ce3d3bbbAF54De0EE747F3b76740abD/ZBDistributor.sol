// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IZombunnies.sol";
import "./AccessControl.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";

contract ZombunniesDistributor is AccessControl {
    IZombunnies public zbToken;
    IERC721 public cbToken;

    uint256 public mintPriceWhitelist = 0.09 ether;
    uint256 public mintPricePublicSale = 0.12 ether;

    uint256 public burnToMintCap = 3026;
    uint256 public burnToMintCount;

    uint256 public mintCap = 1308;
    uint256 public mintCount;

    uint256 public whitelistMintCap = 666;
    uint256 public whitelistMintCount;

    uint256 public maxMintAllowed = 2;
    uint256 public totalBunniesSacrificed;

    address public withdrawWallet;
    address public upgradedToAddress;

    bool public whitelistOnly = true;
    bool public mintingPause;
    bool internal locked;

    mapping(address => bool) public whiteList;
    mapping(address => uint256) public whitelistUserMintCount;
    mapping(uint256 => uint256[]) public sacrificedBunnies;

    event MintZombunnyWithChainBunnies(
        uint256[] indexed _CBTokenIds,
        uint256 indexed _ZBTokenId
    );

    receive() external payable {}

    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Caller is not admin"
        );
        _;
    }

    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    constructor(
        IZombunnies _zbToken,
        IERC721 _cbToken,
        address _withdrawWallet
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        withdrawWallet = _withdrawWallet;

        zbToken = _zbToken;
        cbToken = _cbToken;
    }

    function whitelistMint(uint256 _num)
        public
        payable
        noReentrant
        returns (bool)
    {
        require(!mintingPause, "Minting paused");
        require(whiteList[_msgSender()], "ONLY WHITELIST USERS");

        require(
            whitelistUserMintCount[_msgSender()] + _num <= maxMintAllowed,
            "Whitelist Mint Limit Exceed "
        );
        require(
            whitelistMintCount + _num <= whitelistMintCap,
            "whitelist mint cap exceed"
        );

        require(
            msg.value >= (mintPriceWhitelist * _num),
            "Insufficient amount provided"
        );

        whitelistUserMintCount[_msgSender()] += _num;
        whitelistMintCount += _num;

        zbToken.mintTokens(_msgSender(), _num);
        return true;
    }

    function mint(uint256 _num) public payable noReentrant returns (bool) {
        require(!mintingPause, "Minting paused");
        require(!whitelistOnly, "ONLY WHITELIST"); //whitelistOnly is false
        require(
            address(0) == upgradedToAddress,
            "Contract has been upgraded to a new address"
        );
        require(_num <= 20, "You can mint a maximum of 20 at once");

        require(
            msg.value >= (mintPricePublicSale * _num),
            "Insufficient amount provided"
        );
        require(
            mintCount + _num <= mintCap,
            "Maximum cap of pay-to-mint reached"
        );
        mintCount += _num;

        zbToken.mintTokens(_msgSender(), _num);

        return true;
    }

    function mintUsingNFT(uint256[] calldata _tokenIds)
        public
        noReentrant
        returns (bool)
    {
        uint256 tokensLength = _tokenIds.length;

        require(!mintingPause, "Minting paused");
        require((tokensLength == 2), "You can only swap 2 for 1");
        require(
            address(0) == upgradedToAddress,
            "Contract has been upgraded to a new address"
        );
        require(whiteList[_msgSender()] || !whitelistOnly, "ONLY WHITELIST");

        require(
            burnToMintCount + 1 <= burnToMintCap,
            "Maximum cap of burn-to-mint reached"
        );

        require(
            (cbToken.isApprovedForAll(_msgSender(), address(this))),
            "not approved chainbunnies"
        );

        uint256 currentZombunnyCount = zbToken.getMintedZombunnies();
        uint256 nextZombunnyId = currentZombunnyCount + 1;

        for (uint256 index; index < tokensLength; index++) {
            cbToken.safeTransferFrom(
                _msgSender(),
                address(0x000000000000000000000000000000000000dEaD),
                _tokenIds[index]
            );
            sacrificedBunnies[nextZombunnyId].push(_tokenIds[index]);
        }

        burnToMintCount++;
        totalBunniesSacrificed += 2;

        zbToken.mintTokens(_msgSender(), 1);

        emit MintZombunnyWithChainBunnies(_tokenIds, nextZombunnyId);

        return true;
    }

    // admin functions
    function withdrawEth() public onlyAdmin {
        uint256 balance = address(this).balance;
        require(balance > 0, "invalid amount to withdraw");
        (bool success, ) = payable(withdrawWallet).call{value: balance}("");
        require(success, "eth transfer failed");
    }

    function updateWithdrawWallet(address _newWallet) external onlyAdmin {
        withdrawWallet = _newWallet;
    }

    function updateMaxMintAllowed(uint256 _newMaxAllowed) external onlyAdmin {
        maxMintAllowed = _newMaxAllowed;
    }

    function togglePause(bool _pause) external onlyAdmin {
        require(mintingPause != _pause, "Already in desired pause state");

        mintingPause = _pause;
    }

    function updateWhitelistPrice(uint256 _newPrice) external onlyAdmin {
        mintPriceWhitelist = _newPrice;
    }

    function updatePublicSalePrice(uint256 _newPrice) external onlyAdmin {
        mintPricePublicSale = _newPrice;
    }

    //whitelist
    function addToWhiteList(address[] calldata entries) external onlyAdmin {
        for (uint256 i = 0; i < entries.length; i++) {
            address entry = entries[i];
            require(entry != address(0), "Cannot add zero address");
            require(!whiteList[entry], "Cannot add duplicate address");

            whiteList[entry] = true;
        }
    }

    function removeFromWhiteList(address[] calldata entries)
        external
        onlyAdmin
    {
        for (uint256 i = 0; i < entries.length; i++) {
            address entry = entries[i];
            require(entry != address(0), "Cannot remove zero address");
            require(whiteList[entry], "Cannot remove non whitelist address");

            whiteList[entry] = false;
        }
    }

    function toggleWhiteListOnly(bool _whitelistOnly) external onlyAdmin {
        whitelistOnly = _whitelistOnly;
    }

    function isOnWhiteList(address addr) external view returns (bool) {
        return whiteList[addr];
    }

    function getSacrificedBunnies(uint256 _zomBunnyID)
        external
        view
        returns (uint256[] memory _sacrificedBunnies)
    {
        _sacrificedBunnies = sacrificedBunnies[_zomBunnyID];
    }

    function upgrade(address _upgradedToAddress) external onlyAdmin {
        upgradedToAddress = _upgradedToAddress;
    }

    function updatePublicMintCap(uint256 _newcap) external onlyAdmin {
        mintCap = _newcap;
    }

    function updateWhitelistMintCap(uint256 _newcap) external onlyAdmin {
        whitelistMintCap = _newcap;
    }

    function updateBurnToMintCap(uint256 _newcap) external onlyAdmin {
        burnToMintCap = _newcap;
    }

    function airdropZombunnies(
        address[] memory _addresses,
        uint256[] memory _quantities
    ) external onlyAdmin {
        require(_addresses.length <= 255, "exceeded address length");
        require(_addresses.length == _quantities.length, "length mismatch");
        for (uint256 i; i < _addresses.length; i++) {
            zbToken.mintTokens(_addresses[i], _quantities[i]);
        }
    }
}
