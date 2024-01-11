// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import "./OwnableUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./ERC721HolderUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./IERC721Metadata.sol";

import "./IFracTokenVault.sol";
import "./IFracVaultFactory.sol";
import "./ITokenVault.sol";

/**
 * @title PartyVault contract
 * @author twitter.com/devloper_eth
 * @notice Nouns party is an effort aimed at making community-driven nouns bidding easier, more interactive, and more likely to win than today's strategies.
 */
// solhint-disable max-states-count
contract PartyVault is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable,
    ERC721HolderUpgradeable
{
    struct Deposit {
        address owner;
        uint256 amount;
        bool tokenClaimed;
    }

    struct ContractState {
        address creator;
        string symbol;
        bool paused;
    }

    struct BuyAttempt {
        uint256 tokenId;
        bool success;
        uint256 totalCost;
        uint32 poolStartAt;
        uint32 poolEndAt;
        address vaultAddress;
    }

    event LogBought(
        address triggeredBy,
        address contractAddress,
        uint256 tokenId,
        address sellerAddress,
        uint256 purchaseEth,
        uint256 feeEth
    );

    event LogClaim(
        address sender,
        address contractAddress,
        uint256 tokenId,
        address fracTokenVaultAddress,
        uint256 depositIdx,
        uint256 tokensAmount
    );

    event LogDeposit(address sender, uint256 amount, address contractAddress);

    event LogWithdraw(address sender, uint256 amount, address contractAddress);

    // tokens are minted at a rate of 1 ETH : 1000 tokens
    uint16 internal constant TOKEN_SCALE = 1000;
    uint256 private constant ETH1_1000 = 1_000_000_000_000_000; // 0.001 eth
    uint256 private constant ETH1_10 = 100_000_000_000_000_000; // 0.1 eth

    address public partyVaultWallet;

    address public fracVaultFactoryAddress;
    IFracVaultFactory public fracVaultFactory;

    mapping(address => Deposit[]) public depositPools;
    mapping(address => uint256) public currentPoolAmount;
    mapping(address => uint32) public currentPoolStartAt;

    mapping(address => BuyAttempt[]) public buyAttempts;

    address[] public contractList;
    mapping(address => ContractState) public contractStates;

    modifier contractExist(address _contractAddress) {
        require(
            contractStates[_contractAddress].creator != address(0),
            "NFTContract must exist"
        );
        _;
    }

    modifier contractNotPaused(address _contractAddress) {
        require(
            contractStates[_contractAddress].creator != address(0),
            "NFTContract must exist"
        );
        require(
            !contractStates[_contractAddress].paused,
            "NFTContract must not paused"
        );
        _;
    }

    modifier ownerOrCreator(address _contractAddress) {
        require(
            contractStates[_contractAddress].creator == msg.sender ||
                owner() == msg.sender,
            "Must be owner or creator"
        );
        _;
    }

    function initialize(
        address _partyVaultWallet,
        address _fracVaultFactoryAddress
    ) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        __ERC721Holder_init();

        require(
            _fracVaultFactoryAddress != address(0),
            "zero fracVaultFactoryAddress"
        );

        partyVaultWallet = _partyVaultWallet;
        fracVaultFactoryAddress = _fracVaultFactoryAddress;
        fracVaultFactory = IFracVaultFactory(_fracVaultFactoryAddress);
    }

    // ======== External: Buy =========

    /**
     * @notice Buy the token by calling targetContract with calldata supplying value
     * @dev Emits a Bought event upon success; reverts otherwise. callable by owner or creator
     * @param _contractAddress the NFT contract address
     * @param _tokenId the NFT token id
     * @param _value the buy now price in wei
     * @param _sellerContract the owner of the NFT token. usually OpenSea
     * @param _calldata the abi encoded call data sent to seller to purchase and transfer ownership to this PartyVault contract
     */
    function buy(
        address _contractAddress,
        uint256 _tokenId,
        uint256 _value,
        address _sellerContract,
        bytes calldata _calldata
    )
        external
        nonReentrant
        contractExist(_contractAddress)
        ownerOrCreator(_contractAddress)
    {
        // check that value is above min to cover gas
        require(_value > 0, "No zero price");
        // check that value is not more than
        // the maximum amount the party can spend while paying ETH fee
        uint256 _fee = (_value * 25) / 1000;
        uint256 _totalCost = _value + _fee;

        require(
            _totalCost <= currentPoolAmount[_contractAddress],
            "Insuffucient funds price + fee"
        );
        // require that the NFT is NOT owned by the Party
        require(
            _getOwner(_contractAddress, _tokenId) != address(this),
            "Own token before call"
        );
        // execute the calldata on the target contract
        (bool _success, bytes memory _returnData) = address(_sellerContract)
            .call{value: _value}(_calldata);
        // require that the external call succeeded
        require(_success, string(_returnData));
        // require that the NFT is owned by the Party
        require(
            _getOwner(_contractAddress, _tokenId) == address(this),
            "Failed to buy token"
        );

        address _vaultAddress = _fractionalizeNFT(
            _contractAddress,
            _tokenId,
            _totalCost
        );
        _settleAfterPurchase(
            _contractAddress,
            _tokenId,
            _totalCost,
            _vaultAddress
        );
        // send ETH fees to PartyVaultWallet,
        _transferETH(partyVaultWallet, _fee);

        emit LogBought(
            msg.sender,
            _contractAddress,
            _tokenId,
            _sellerContract,
            _value,
            _fee
        );
    }

    /**
    * @notice Puts ETH into our desposit pool.
    * @param _contractAddress the NFT contract address
    */

    function deposit(address _contractAddress)
        external
        payable
        nonReentrant
        contractNotPaused(_contractAddress)
    {
        // Verify deposit amount to ensure fractionalizing will produce whole numbers.
        require(msg.value % ETH1_1000 == 0, "Must be in 0.001 ETH increments");

        // v0 asks for a 0.1 eth minimum deposit.
        // v1 will ask for 0.001 eth as minimum deposit.
        require(msg.value >= ETH1_10, "Minimum deposit is 0.1 ETH");

        Deposit memory d = Deposit({
            owner: msg.sender,
            amount: msg.value,
            tokenClaimed: false
        });

        depositPools[_contractAddress].push(d);

        uint256 _prevAmount = currentPoolAmount[_contractAddress];

        currentPoolAmount[_contractAddress] += msg.value;

        require(_prevAmount < currentPoolAmount[_contractAddress], "No overflow");

        emit LogDeposit(msg.sender, msg.value, _contractAddress);
    }

    /**
    * @notice get the desposit pools to check withdrawable and claimable
    * @param _contractAddress the NFT contract address
    * @param _isUnspent true: withdrable, false: claimable
    */

    function getDeposits(address _contractAddress, bool _isUnspent)
        external
        view
        contractExist(_contractAddress)
        returns (Deposit[] memory _items)
    {
        uint256 _itemsCount = currentPoolStartAt[_contractAddress];
        if (_isUnspent) {
            _itemsCount = depositPools[_contractAddress].length -
            currentPoolStartAt[_contractAddress];
        }
        _items = new Deposit[](_itemsCount);
        uint32 _itemsIdx = 0;
        uint32 _poolIdx = 0;
        if (_isUnspent) {
            _poolIdx = currentPoolStartAt[_contractAddress];
            _itemsCount = depositPools[_contractAddress].length;
        }
        for (
            ;
            _poolIdx < _itemsCount;
            _poolIdx++
        ) {
            Deposit memory d = depositPools[_contractAddress][_poolIdx];
            _items[_itemsIdx] = d;
            _itemsIdx += 1;
        }
    }

    /**
    * @notice claim your specific token
    * @param _contractAddress the NFT contract address
    * @param _attemptIdx index to indicate which buyAttempt to claim
    * @param _depositIdx index to indicate which buyAttempt to claim

    */
    function claim(
        address _contractAddress,
        uint256 _attemptIdx,
        uint256 _depositIdx
    ) external nonReentrant contractExist(_contractAddress)
    {
        BuyAttempt memory _attempt = buyAttempts[_contractAddress][_attemptIdx];
        require(_attempt.success, "Must be a success purchase");
        require(
            _depositIdx >= _attempt.poolStartAt &&
                _depositIdx <= _attempt.poolEndAt,
            "Must claim inside attempt pool"
        );
        Deposit memory _deposit = depositPools[_contractAddress][_depositIdx];
        require(_deposit.owner == msg.sender, "Sender must match deposit");
        require(!_deposit.tokenClaimed, "Token mustn't be claimed before");

        uint256 _tokenAmount = _transferToken(_attempt.vaultAddress, _deposit.owner, _deposit.amount);
        depositPools[_contractAddress][_depositIdx].tokenClaimed = true;
        emit LogClaim(
            msg.sender,
            _contractAddress,
            _attempt.tokenId,
            _attempt.vaultAddress,
            _depositIdx,
            _tokenAmount
        );
    }

    /// @notice Withdraw deposits that haven't been used.
    function withdraw(address _contractAddress, uint32 _poolIdx)
        external
        nonReentrant
        contractExist(_contractAddress)
    {
        require(
            _poolIdx >= currentPoolStartAt[_contractAddress],
            "Must be unused fund"
        );
        require(
            _poolIdx < depositPools[_contractAddress].length,
            "Must be valid poolIdx"
        );
        Deposit memory d = depositPools[_contractAddress][_poolIdx];
        require(d.owner == msg.sender, "Must be owner of the deposit");
        currentPoolAmount[_contractAddress] -= d.amount;
        _transferETH(msg.sender, d.amount);
        if (_poolIdx < depositPools[_contractAddress].length - 1) {
            depositPools[_contractAddress][_poolIdx] = depositPools[
                _contractAddress
            ][depositPools[_contractAddress].length - 1];
        }
        depositPools[_contractAddress].pop();
        emit LogWithdraw(msg.sender, d.amount, _contractAddress);
    }

    function addContract(address _contractAddress, string calldata _symbol)
        external
        nonReentrant
    {
        require(
            contractStates[_contractAddress].creator == address(0),
            "NFTContract must not exist"
        );
        contractStates[_contractAddress] = ContractState({
            creator: msg.sender,
            symbol: _symbol,
            paused: false
        });
        contractList.push(_contractAddress);
    }

    function setSymbol(address _contractAddress, string calldata _symbol)
        external
        nonReentrant
        contractExist(_contractAddress)
        ownerOrCreator(_contractAddress)
    {
        contractStates[_contractAddress].symbol = _symbol;
    }

    function transferCreator(address _contractAddress, address _newCreator)
        external
        nonReentrant
        contractExist(_contractAddress)
        ownerOrCreator(_contractAddress)
    {
        require(_newCreator != address(0), "Must be valid address");
        contractStates[_contractAddress].creator = _newCreator;
    }

    function setPause(address _contractAddress, bool _pause)
        external
        nonReentrant
        contractExist(_contractAddress)
        ownerOrCreator(_contractAddress)
    {
        require(contractStates[_contractAddress].paused != _pause, "Pause state unchanged");
        contractStates[_contractAddress].paused = _pause;
        // Emit pause event
    }

    function setPartyVaultWallet(address _addr) external nonReentrant onlyOwner {
        partyVaultWallet = _addr;
    }

    function _settleAfterPurchase(
        address _contractAddress,
        uint256 _tokenId,
        uint256 _totalCost,
        address _vaultAddress
    ) internal {
        currentPoolAmount[_contractAddress] -= _totalCost;
        uint32 _readingIndex = currentPoolStartAt[_contractAddress];
        uint32 _previousStartAt = _readingIndex;
        uint256 _accAmount = 0;
        Deposit memory _currentDeposit;
        for (
            ;
            _readingIndex < depositPools[_contractAddress].length;
            _readingIndex++
        ) {
            _currentDeposit = depositPools[_contractAddress][_readingIndex];
            _accAmount += _currentDeposit.amount;
            if (_accAmount >= _totalCost) {
                break;
            }
        }
        // new start at
        currentPoolStartAt[_contractAddress] = _readingIndex + 1;
        uint256 _remaining = _accAmount - _totalCost;
        if (_remaining > 0) {
            depositPools[_contractAddress][_readingIndex].amount -= _remaining;
            depositPools[_contractAddress].push(
                Deposit({
                    owner: _currentDeposit.owner,
                    amount: _remaining,
                    tokenClaimed: false
                })
            );
        }
        buyAttempts[_contractAddress].push(
            BuyAttempt({
                tokenId: _tokenId,
                success: true,
                totalCost: _totalCost,
                poolStartAt: _previousStartAt,
                poolEndAt: _readingIndex,
                vaultAddress: _vaultAddress
            })
        );
    }

    /**
     * @notice Upon winning the token, transfer the NFT
     * to fractional.art vault & mint fractional ERC-20 tokens
     */
    function _fractionalizeNFT(
        address _contractAddress,
        uint256 _tokenId,
        uint256 _totalCost
    ) internal returns (address) {
        // approve fractionalized NFT Factory to withdraw NFT
        IERC721Metadata _nftContract = IERC721Metadata(_contractAddress);
        _nftContract.approve(address(fracVaultFactory), _tokenId);
        // deploy fractionalized NFT vault

        string memory symbol = string(
            abi.encodePacked(
                contractStates[_contractAddress].symbol,
                StringsUpgradeable.toString(_tokenId)
            )
        );

        uint256 _totalToken = (_totalCost * 1025) / 1000;
        uint256 _vaultNumber = fracVaultFactory.mint(
            symbol,
            symbol,
            _contractAddress,
            _tokenId,
            _totalToken * TOKEN_SCALE,
            _totalToken * 5,
            0
        );

        // store token vault address to storage
        address _tokenVaultAddress = fracVaultFactory.vaults(_vaultNumber);
        // transfer curator to null address (burn the curator role)
        ITokenVault(_tokenVaultAddress).updateCurator(address(0));

        uint256 _partyVaultToken = _totalToken - _totalCost;
        _transferToken(_tokenVaultAddress, partyVaultWallet, _partyVaultToken);
        return _tokenVaultAddress;
    }

    /**
     * @notice Query the NFT contract to get the token owner
     * @dev nftContract must implement the ERC-721 token standard exactly:
     * function ownerOf(uint256 _tokenId) external view returns (address);
     * See https://eips.ethereum.org/EIPS/eip-721
     * @dev Returns address(0) if NFT token or NFT contract
     * no longer exists (token burned or contract self-destructed)
     * @return _owner the owner of the NFT
     */
    function _getOwner(address _contractAddress, uint256 _tokenId)
        internal
        view
        returns (address _owner)
    {
        (bool _success, bytes memory _returnData) = _contractAddress.staticcall(
            abi.encodeWithSignature("ownerOf(uint256)", _tokenId)
        );
        if (_success && _returnData.length > 0) {
            _owner = abi.decode(_returnData, (address));
        }
    }

    function _transferToken(
        address _vaultAddress,
        address _to,
        uint256 _value
    ) private returns (uint256 _tokenAmount) {
        ITokenVault _tokenVault = ITokenVault(_vaultAddress);
        // guard against rounding errors;
        // if token amount to send is greater than contract balance,
        // send full contract balance
        uint256 _partyBalance = _tokenVault.balanceOf(address(this));
        _tokenAmount = _value * TOKEN_SCALE;
        if (_tokenAmount > _partyBalance) {
            _tokenAmount = _partyBalance;
        }
        _tokenVault.transfer(_to, _tokenAmount);
    }

    // @dev Authorize OpenZepplin's upgrade function, guarded by onlyOwner.
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {} // solhint-disable-line no-empty-blocks

    /// @dev Transfer ETH and revert if unsuccessful. Only forward 30,000 gas to the callee.
    function _transferETH(address _to, uint256 _value) private {
        (bool success, ) = _to.call{value: _value, gas: 30_000}(new bytes(0)); // solhint-disable-line avoid-low-level-calls
        require(success, "Transfer failed");
    }

    /// @dev Allow contract to receive Eth. For example when we are outbid.
    receive() external payable {} // solhint-disable-line no-empty-blocks
}
