// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./SafeMath.sol";
import "./ERC721A.sol";
import "./console.sol";

contract TheBearCollective is Ownable, ERC721A, ReentrancyGuard {
    using SafeMath for uint256;

    enum STAGE {
        NOT_STARTED,
        PRESALE,
        PUBLIC
    }

    struct SaleConfig {
        uint256 saleStart;
        uint256 mintPrice;
        uint256 mintLimit;
        uint256 minted;
        bytes slot;
    }

    SaleConfig public ogSaleConfig;
    SaleConfig public wlSaleConfig;
    SaleConfig public publicSaleConfig;

    address[] public airdrop;
    mapping(address => bool) public freeMintEligible;
    mapping(address => bool) public freeMintClaimed;

    address payable public devWallet =
        payable(0x40638c0528eaC13FB5931131B70D7AF295368ABb);
    bool public set = false;
    bool public paused = false;
    uint256 public presaleEndTime = 0;
    string public _baseTokenURI;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _maxMintsPerBatch,
        uint256 _collectionSize
    ) ERC721A(_name, _symbol, _maxMintsPerBatch, _collectionSize) {}

    //@dev Set the current sale configs
    //@dev Note the slot provided to prevent conflicts, and if a new slow is provided, this clears the mapping!
    function setSaleConfigs(
        SaleConfig memory _ogSaleConfig,
        SaleConfig memory _wlSaleConfig,
        SaleConfig memory _publicSaleConfig,
        uint256 _presaleEndTime
    ) public onlyOwner {
        require(
            _ogSaleConfig.saleStart == _wlSaleConfig.saleStart,
            "Presale configs must be the same"
        );
        require(
            _presaleEndTime > _ogSaleConfig.saleStart &&
                _presaleEndTime <= _publicSaleConfig.saleStart,
            "Presale end must be between presale start and public start"
        );
        ogSaleConfig = _ogSaleConfig;
        wlSaleConfig = _wlSaleConfig;
        publicSaleConfig = _publicSaleConfig;
        presaleEndTime = _presaleEndTime;
        set = true;
    }

    //@dev SaleConfig does not directly hold the allowed mapping
    //@dev It only holds the pointer address of where the mapping is at
    //@dev Have to load it using assembly, and get the value accordingly.
    //@dev If mapping(address => bool) map and map starts at slot x
    //@dev we can find map[address] value by loading the value at keccak256(address . slot)
    function getAllowList(SaleConfig memory saleConfig, address inputAddress)
        internal
        view
        returns (bool result)
    {
        bytes32 slot = keccak256(saleConfig.slot);
        assembly {
            //Store address in free memory pointer
            mstore(0, inputAddress)
            //Store starting slot in the next 32 bits
            mstore(32, slot)
            //Compute keccak256(address.slot)
            let hash := keccak256(0, 64)
            //Value is located there and load it
            result := sload(hash)
        }
    }

    function setAllowList(
        SaleConfig memory saleConfig,
        address inputAddress,
        bool input
    ) internal {
        bytes32 slot = keccak256(saleConfig.slot);
        assembly {
            //Store address in free memory pointer
            mstore(0, inputAddress)
            //Store starting slot in the next 32 bits
            mstore(32, slot)
            //Compute keccak256(address.slot)
            let hash := keccak256(0, 64)
            //Value is located there and load it
            sstore(hash, input)
        }
    }

    function isOg(address addr) public view returns (bool) {
        return getAllowList(ogSaleConfig, addr);
    }

    function isWl(address addr) public view returns (bool) {
        return getAllowList(wlSaleConfig, addr);
    }

    //@dev Based on the current block time, we extract the current stage the sale process is at
    function getCurrentStage() public view returns (STAGE) {
        uint256 currentTime = block.timestamp;
        uint256 ogSaleTime = ogSaleConfig.saleStart;
        uint256 wlSaleTime = wlSaleConfig.saleStart;
        uint256 publicSaleTime = publicSaleConfig.saleStart;
        //ogSaleTime and wlSaleTime is the same. Ensure its below public saletime
        if (
            currentTime >= ogSaleTime &&
            currentTime >= wlSaleTime &&
            currentTime < presaleEndTime
        ) {
            return STAGE.PRESALE;
        } else if (currentTime >= publicSaleTime) {
            return STAGE.PUBLIC;
        }
        return STAGE.NOT_STARTED;
    }

    //@dev Gets the current saleConfig
    //@dev Internal since we need to return the saleconfig struct storage pointer
    function getSaleConfig(address _caller)
        internal
        view
        returns (SaleConfig storage)
    {
        STAGE stage = getCurrentStage();
        if (stage == STAGE.PRESALE) {
            bool isOgAllowed = isOg(_caller);
            bool isWlAllowed = isWl(_caller);
            require(
                isOgAllowed || isWlAllowed,
                "Minter is not in OG or WL list"
            );
            if (isOgAllowed && !isWlAllowed) {
                return ogSaleConfig;
            } else if (!isOgAllowed && isWlAllowed) {
                return wlSaleConfig;
            }
        }
        return publicSaleConfig;
    }

    //@dev Adds a list of addresses to the airdroppedAddress list
    function addAddressListToAirdrop(address[] memory addresses)
        public
        onlyOwner
    {
        for (uint256 i; i < addresses.length; i++) {
            airdrop.push(addresses[i]);
        }
    }

    //@dev Adds an address to the OG whitelist
    function addAddressListToOg(address[] memory addresses) public onlyOwner {
        for (uint256 i; i < addresses.length; i++) {
            setAllowList(ogSaleConfig, addresses[i], true);
        }
    }

    //@dev Adds an address to the WL whitelist
    function addAddressListToWl(address[] memory addresses) public onlyOwner {
        for (uint256 i; i < addresses.length; i++) {
            setAllowList(wlSaleConfig, addresses[i], true);
        }
    }

    //@dev Marks an address as being eligble fo a free first mint.
    function addAddressListToFreeMint(address[] memory addresses)
        public
        onlyOwner
    {
        for (uint256 i; i < addresses.length; i++) {
            freeMintEligible[addresses[i]] = true;
        }
    }

    //@dev Mints 1 NFT to all addresses in the airdrop
    function mintAirdrop() public onlyOwner {
        for (uint256 i; i < airdrop.length; i++) {
            _safeMint(airdrop[i], 1);
        }
        delete airdrop;
    }

    //@dev Execute the mint function
    //@dev Calculates the total cost by getting the current mint price
    //@dev If user is eligble for a free mint and has not claimed
    //@dev Reduce the total cost by 1 NFT
    function mint(uint256 quantity) public payable {
        STAGE stage = getCurrentStage();
        require(stage != STAGE.NOT_STARTED, "Mint has not started yet");
        require(!paused, "Minting is currently paused");
        require(set, "Configs has yet to be set");

        SaleConfig storage saleConfig = getSaleConfig(msg.sender);
        uint256 limit = saleConfig.mintLimit;
        uint256 totalPrice = quantity.mul(saleConfig.mintPrice);

        //If eliglble for a free mint and not claimed, reduce the total cost by 1 NFT
        if (freeMintEligible[msg.sender] && !freeMintClaimed[msg.sender]) {
            totalPrice = totalPrice.sub(saleConfig.mintPrice);
            freeMintClaimed[msg.sender] = true;
        }

        //Ensure that the total minted for the user is below the limit which is n, or n+1 if free mint eligble
        require(
            _numberMinted(msg.sender) + quantity <= limit,
            "Exceed maximum amount of mints possible"
        );
        refundIfOver(totalPrice);
        _safeMint(msg.sender, quantity);
    }

    //@Dev check if the sent amount is at least the minimum required, and then transfer to this contract
    function refundIfOver(uint256 totalPrice) private {
        require(msg.value >= totalPrice, "Need to send more ETH.");
        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value - totalPrice);
        }
    }

    //@dev Get the baseURI
    //@dev Override's ERC721 _baseURI() function
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    //@dev Set the baseURI
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    //@dev Return the collection size
    function getCollectionSize() external view returns (uint256) {
        return collectionSize;
    }

    //@dev Return max mint
    function getMaxBatchMint() external view returns (uint256) {
        return maxBatchSize;
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = devWallet.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function setOwnersExplicit(uint256 quantity)
        external
        onlyOwner
        nonReentrant
    {
        _setOwnersExplicit(quantity);
    }

    //@dev TogglePause
    function togglePause() public onlyOwner {
        paused = !paused;
    }

    function getPaused() public view returns (bool) {
        return paused;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getAirdropAddresses() public view returns (address[] memory) {
        return airdrop;
    }
}
