// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./ERC721Upgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./ERC721URIStorageUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./IQuoter.sol";
import "./ERC721HolderUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./ITreasury.sol";

contract GoodNft is
    Initializable,
    ERC721Upgradeable,
    PausableUpgradeable,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable,
    ERC721HolderUpgradeable,
    ERC721URIStorageUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    uint24 public poolFee;
    uint64 constant constants = 10000;
    address public treasuryContractAddress;
    address public escrowContractAddress;
    IERC20Upgradeable public WETHaddress;
    IERC20Upgradeable public usdc;
    IQuoter public quoter;
    uint64 public charityFee;
    uint64 public charityCoordinatorFee;
    uint64 public platformFee;
    uint64 public listorFee;
    uint64 public escrowFee;

    CountersUpgradeable.Counter public _tokenId;

    mapping(uint => NftListing) public _tokenIdToListing;

    struct NftListing {
        address charity;
        address charityCoordinator;
        address lister;
        uint priceInUSD;
        bool listed;
    }
    event NftListed(uint tokenId, address lister, uint price);

    event NftSold(uint tokenId, address buyer, uint amount);

    event UpdateTreasuyAddress(address newAddress);

    event EmergencyWithdrawal(address receiver, address tokenAddress);

    event LogQuoterFailure(string reason);

    event LogQuoterFailureUint(uint reason);

    event LogQuoterFailureBytes(bytes reason);

    event EmergencyWithdrawalERC721(
        address receiver,
        address tokenAddress,
        uint256[] tokenIds
    );

    event UpdateUSDCaddress(address usdc);
    event UpdateWETHaddress(address weth);

    event UpdateFeeConfig(
        uint64 newCharityFee,
        uint64 newCharityCoordinatorFee,
        uint64 newPlatformFee,
        uint64 newListorFee,
        uint64 newEscrowFee
    );

    event ReceivedEther(address payer, uint amount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    modifier isAdmin() {
        require(
            TreasuryContract(treasuryContractAddress).isAdmin(msg.sender),
            "Not authorized"
        );
        _;
    }

    modifier isEntrepreneur() {
        require(
            TreasuryContract(treasuryContractAddress).isEntrepreneur(
                msg.sender
            ),
            "Not authorized"
        );
        _;
    }

    /**
     * @notice Initializes contract .
     * @param   _treasuryContractAddress  .
     * @param   _WETHaddress  .
     * @param   _usdcTokenAddress  .
     * @param   _quoter  .
     * @param   _charityFee  .
     * @param   _charityCoordinatorFee  .
     * @param   _platformFee  .
     * @param   _listorFee  .
     * @param   _poolFee  .
     */
    function initialize(
        address _treasuryContractAddress,
        address _escrowContractAddress,
        IERC20Upgradeable _WETHaddress,
        IERC20Upgradeable _usdcTokenAddress,
        IQuoter _quoter,
        uint64 _charityFee,
        uint64 _charityCoordinatorFee,
        uint64 _platformFee,
        uint64 _listorFee,
        uint24 _poolFee,
        uint64 _escrowFee
    ) public initializer {
        __ERC721_init("COMMIT GOOD", "GOOD");
        __ERC721URIStorage_init();
        __Pausable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        __ERC721Holder_init();
        WETHaddress = _WETHaddress;
        charityFee = _charityFee;
        platformFee = _platformFee;
        charityCoordinatorFee = _charityCoordinatorFee;
        listorFee = _listorFee;
        quoter = _quoter;
        usdc = _usdcTokenAddress;
        poolFee = _poolFee;
        treasuryContractAddress = _treasuryContractAddress;
        escrowFee = _escrowFee;
        escrowContractAddress = _escrowContractAddress;
    }

    /**
     * @notice Provides functionality to pause transfer,caller must have Admin role .
     */
    function pause() public isAdmin {
        _pause();
    }

    /**
     * @notice Provides functionality to enable transfer,caller needs to have Admin role .
     */
    function unpause() public isAdmin {
        _unpause();
    }

    /**
     * @notice Provides functionality to generate bytesPath for getUniswapV3Amount function..
     */
    function convertToBytesPath(
        address[] memory _path
    ) private view returns (bytes memory bytesPath) {
        uint256 i;
        uint256 pathLength = _path.length - 1;
        for (i = 0; i < pathLength; ) {
            bytesPath = abi.encodePacked(bytesPath, _path[i], poolFee);
            unchecked {
                i++;
            }
        }
        bytesPath = abi.encodePacked(bytesPath, _path[i]);
    }

    /**
     * @notice Provides functionality to get amount out from Uniswap v3
     */
    function getUniswapv3Amount(
        address[] memory _pathaddress,
        uint amountIn
    ) private returns (uint) {
        bytes memory path = convertToBytesPath(_pathaddress);

        try quoter.quoteExactInput(path, amountIn) returns (uint256 amountOut) {
            return (amountOut);
        } catch Error(string memory reason) {
            emit LogQuoterFailure(reason);
            return 0;
        } catch Panic(uint reason) {
            emit LogQuoterFailureUint(reason);
            return 0;
        } catch (bytes memory reason) {
            emit LogQuoterFailureBytes(reason);
            return 0;
        }
    }

    /**
     * @notice  .Provides functionality to mint NFT to this contract and puts the NFT on sale for users to buy at the given price in USDT,caller must have Entrepreneur role.    .
     * @param   _charity  .
     * @param   _charityCoordinator  .
     * @param   _priceInUsd  .
     * @param   _uri  .
     */
    function mintAndList(
        address _charity,
        address _charityCoordinator,
        uint _priceInUsd,
        string calldata _uri
    ) external isEntrepreneur nonReentrant {
        require(_priceInUsd > 0, "USD amount should not be zero");
        require(bytes(_uri).length > 0, "Uri cannot be empty string");
        _tokenId.increment();
        uint256 tokenId = _tokenId.current();
        _safeMint(address(this), tokenId);
        _setTokenURI(tokenId, _uri);
        _tokenIdToListing[tokenId] = NftListing(
            _charity,
            _charityCoordinator,
            msg.sender,
            _priceInUsd,
            true
        );
        emit NftListed(tokenId, msg.sender, _priceInUsd);
    }

    /**
     * @notice Provides functionality to purchase NFT by giving ETH equivalent to the price of NFT in USDT .
     * @param   _purchaseTokenId  .
     */
    function purchase(uint _purchaseTokenId) external payable nonReentrant {
        NftListing memory listingData = _tokenIdToListing[_purchaseTokenId];
        require(listingData.listed, "Listing doesn't exist");

        uint256 _amount = msg.value;
        require(_amount > 0, "GoodNftMarket: amount zero");
        address[] memory path = new address[](2);
        path[0] = address(WETHaddress);
        path[1] = address(usdc);

        uint usdc_equivalent_value = getUniswapv3Amount(path, _amount);
        require(
            usdc_equivalent_value >= listingData.priceInUSD,
            "ETH amount less than nft price"
        );

        _tokenIdToListing[_purchaseTokenId].listed = false;

        uint charityShare = (_amount * charityFee) / constants;
        uint charityCoordinatorShare = (_amount * charityCoordinatorFee) /
            constants;
        uint platformShare = (_amount * platformFee) / constants;
        uint listorShare = (_amount * listorFee) / constants;
        uint escrowShare = (_amount * escrowFee) / constants;

        _sendEthersTo(listingData.charity, charityShare);
        _sendEthersTo(listingData.charityCoordinator, charityCoordinatorShare);
        _sendEthersTo(listingData.lister, listorShare);
        _sendEthersTo(treasuryContractAddress, platformShare);
        _sendEthersTo(escrowContractAddress, escrowShare);

        IERC721Upgradeable(this).safeTransferFrom(
            address(this),
            msg.sender,
            _purchaseTokenId
        );
        emit NftSold(_purchaseTokenId, msg.sender, _amount);
    }

    /**
     * @notice Provides functionality to get token data .
     * @param   _tokenIdData  .
     */
    function getNFTData(
        uint _tokenIdData
    ) external view returns (NftListing memory) {
        NftListing memory listingData = _tokenIdToListing[_tokenIdData];
        return listingData;
    }

    /**
     * @notice  Provides functionality to update fees,caller must have Admin role .
     * @param   _charityFee  .
     * @param   _platformFee  .
     * @param   _charityCoordinatorFee  .
     * @param   _listorFee  .
     */
    function updateFeeConfig(
        uint64 _charityFee,
        uint64 _charityCoordinatorFee,
        uint64 _platformFee,
        uint64 _listorFee,
        uint64 _escrowFee
    ) external isAdmin {
        require(
            _charityFee + _platformFee + _charityCoordinatorFee + _listorFee ==
                constants,
            "Invalid fee configurations"
        );
        charityFee = _charityFee;
        platformFee = _platformFee;
        charityCoordinatorFee = _charityCoordinatorFee;
        listorFee = _listorFee;
        escrowFee = _escrowFee;
        emit UpdateFeeConfig(
            charityFee,
            charityCoordinatorFee,
            platformFee,
            listorFee,
            escrowFee
        );
    }

    /**
     * @notice Provides functionality to update treasury contract address,caller must have Admin role .
     * @param   _treasuryContractAddress  .
     */
    function updateTreasuryAddress(
        address _treasuryContractAddress
    ) external isAdmin {
        require(
            _treasuryContractAddress != address(0),
            "GoodNFTMarket: address zero"
        );
        treasuryContractAddress = _treasuryContractAddress;
        emit UpdateTreasuyAddress(_treasuryContractAddress);
    }

    /**
     * @notice Provides functionality to update usdc contract address,caller must have Admin role .
     * @param   _usdc  .
     */
    function updateUSDCaddress(IERC20Upgradeable _usdc) external isAdmin {
        require(address(_usdc) != address(0), "GoodNFTMarket: address zero");
        usdc = _usdc;
        emit UpdateUSDCaddress(address(_usdc));
    }

    /**
     * @notice Provides functionality to update weth contract address,caller must have Admin role .
     * @param   _weth  .
     */
    function updateWETHaddress(IERC20Upgradeable _weth) external isAdmin {
        require(address(_weth) != address(0), "GoodNFTMarket: address zero");
        WETHaddress = _weth;
        emit UpdateWETHaddress(address(_weth));
    }

    /**
     * @notice  Provides functionality to emergency withdraw any ERC20 or Ether(if token address is address(0))
     * token locked on the contract, caller must have Admin role.
     * @param   _recieverAddress  .
     * @param   _tokenAddress  .
     */
    function emergencyWithdraw(
        address payable _recieverAddress,
        address _tokenAddress
    ) external isAdmin nonReentrant {
        require(
            _recieverAddress != address(0),
            "GoodNFTMarket: Receiver is zero address"
        );
        if (_tokenAddress == address(0)) {
            uint256 balance = address(this).balance;
            (bool sent, ) = _recieverAddress.call{value: balance}("");
            require(sent, "GoodNFTMarket: Failed to send Ether");
        } else {
            uint256 balance = IERC20Upgradeable(_tokenAddress).balanceOf(
                address(this)
            );
            require(balance > 0, "GoodNFTMarket: Insufficient balance");
            IERC20Upgradeable(_tokenAddress).safeTransfer(
                _recieverAddress,
                balance
            );
        }
        emit EmergencyWithdrawal(_recieverAddress, _tokenAddress);
    }

    /**
     * @notice  Provides functionality to emergency withdraw any ERC721 token locked on the contract,caller must have Admin role .
     * @param   _recieverAddress  .
     * @param   _tokenAddress  .
     * @param   _tokenIds  .
     */
    function emergencyWithdrawERC721(
        address _recieverAddress,
        address _tokenAddress,
        uint256[] calldata _tokenIds
    ) external isAdmin {
        uint256 length = _tokenIds.length;
        for (uint256 i = 0; i < length; ) {
            IERC721Upgradeable(_tokenAddress).safeTransferFrom(
                address(this),
                _recieverAddress,
                _tokenIds[i]
            );
            unchecked {
                i++;
            }
        }
        emit EmergencyWithdrawalERC721(
            _recieverAddress,
            _tokenAddress,
            _tokenIds
        );
    }

    /**
     * @notice Internal function to send given amount of ethers to provided receiver address
     * @param _receiver .
     * @param _amount .
     */
    function _sendEthersTo(address _receiver, uint256 _amount) internal {
        require(
            _receiver != address(0) && _amount != 0,
            "GoodNftMarket: address or amount is zero"
        );
        (bool sent, ) = payable(_receiver).call{value: _amount}("");
        require(sent, "GoodMarket: Send ethers to failed");
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    /**
     * @notice  Upgrades the contracts by adding new implementation contract,caller needs to have Admin role .
     * @param   newImplementation  .
     */
    function _authorizeUpgrade(
        address newImplementation
    ) internal override isAdmin {}

    // The following functions are overrides required by Solidity.

    function _burn(
        uint256 tokenId
    ) internal override(ERC721Upgradeable, ERC721URIStorageUpgradeable) {
        super._burn(tokenId);
    }

    /**
     * @dev Receive function for receiving Ether
     */
    receive() external payable {
        emit ReceivedEther(_msgSender(), msg.value);
    }

    /**
     * @notice  Provides functionality to get token uri corresponding to a tokenId  .
     * @param   tokenId  .
     * @return  string  .
     */
    function tokenURI(
        uint256 tokenId
    )
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
}
