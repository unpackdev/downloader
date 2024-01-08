// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./IERC721.sol";
import "./ERC721HolderUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./Counters.sol";
import "./IERC721VaultFactory.sol";
import "./ITokenVault.sol";

interface IBounty {
    function redeemBounty(
        IBountyRedeemer redeemer,
        uint256 amount,
        bytes calldata data
    ) external;
}

interface IBountyRedeemer {
    function onRedeemBounty(address initiator, bytes calldata data)
        external
        payable
        returns (bytes32);
}

// @notice Bounty isn't upgradeable, but because it is deploys as a
// static proxy, needs to extend upgradeable contracts.
contract Bounty is
    ReentrancyGuardUpgradeable,
    ERC721HolderUpgradeable,
    IBounty
{
    using Counters for Counters.Counter;

    enum BountyStatus {
        ACTIVE,
        ACQUIRED,
        EXPIRED
    }

    struct Contribution {
        uint256 priorTotalContributed;
        uint256 amount;
    }

    // tokens are minted at a rate of 1 ETH : 1000 tokens
    uint16 internal constant TOKEN_SCALE = 1000;
    uint8 internal constant RESALE_MULTIPLIER = 2;

    // immutable (across clones)
    address public immutable gov;
    IERC721VaultFactory public immutable tokenVaultFactory;

    // immutable (at clone level)
    IERC721 public nftContract;
    uint256 public nftTokenID;
    string public name;
    string public symbol;
    uint256 public contributionCap;
    uint256 public expiryTimestamp;

    // mutables
    mapping(address => Contribution[]) public contributions;
    mapping(address => uint256) public totalContributedByAddress;
    mapping(address => bool) public claimed;
    uint256 public totalContributed;
    uint256 public totalSpent;
    ITokenVault public tokenVault;
    Counters.Counter public contributors;

    event Contributed(address indexed contributor, uint256 amount);

    event Acquired(uint256 amount);

    event Claimed(
        address indexed contributor,
        uint256 tokenAmount,
        uint256 ethAmount
    );

    modifier onlyGov() {
        require(msg.sender == gov, "Bounty:: only callable by gov");
        _;
    }

    constructor(address _gov, IERC721VaultFactory _tokenVaultFactory) {
        gov = _gov;
        tokenVaultFactory = _tokenVaultFactory;
    }

    function initialize(
        IERC721 _nftContract,
        uint256 _nftTokenID,
        string memory _name,
        string memory _symbol,
        uint256 _contributionCap,
        uint256 _duration
    ) external initializer {
        __ReentrancyGuard_init();
        __ERC721Holder_init();

        nftContract = _nftContract;
        nftTokenID = _nftTokenID;
        name = _name;
        symbol = _symbol;
        contributionCap = _contributionCap;
        expiryTimestamp = block.timestamp + _duration;

        require(
            IERC721(nftContract).ownerOf(nftTokenID) != address(0),
            "Bounty::initialize: Token does not exist"
        );
    }

    // @notice contribute (via msg.value) to active bounty as long as the contribution cap has not been reached
    function contribute() external payable nonReentrant {
        require(
            status() == BountyStatus.ACTIVE,
            "Bounty::contribute: bounty not active"
        );
        address _contributor = msg.sender;
        uint256 _amount = msg.value;
        require(_amount > 0, "Bounty::contribute: must contribute more than 0");
        require(
            contributionCap == 0 || totalContributed < contributionCap,
            "Bounty::contribute: at max contributions"
        );

        if (contributions[_contributor].length == 0) {
            contributors.increment();
        }

        Contribution memory _contribution = Contribution({
            amount: _amount,
            priorTotalContributed: totalContributed
        });
        contributions[_contributor].push(_contribution);
        totalContributedByAddress[_contributor] =
            totalContributedByAddress[_contributor] +
            _amount;
        totalContributed = totalContributed + _amount;
        emit Contributed(_contributor, _amount);
    }

    // @notice uses the redeemer to swap `_amount` ETH for the NFT
    // @param _redeemer The callback to acquire the NFT
    // @param _amount The amount of the bounty to redeem. Must be <= MIN(totalContributed, contributionCap)
    // @param _data Arbitrary calldata for the callback
    function redeemBounty(
        IBountyRedeemer _redeemer,
        uint256 _amount,
        bytes calldata _data
    ) external override nonReentrant {
        require(
            status() == BountyStatus.ACTIVE,
            "Bounty::redeemBounty: bounty isn't active"
        );
        require(totalSpent == 0, "Bounty::redeemBounty: already acquired");
        require(_amount > 0, "Bounty::redeemBounty: cannot redeem for free");
        require(
            _amount <= totalContributed && _amount <= contributionCap,
            "Bounty::redeemBounty: not enough funds"
        );
        totalSpent = _amount;
        require(
            _redeemer.onRedeemBounty{value: _amount}(msg.sender, _data) ==
                keccak256("IBountyRedeemer.onRedeemBounty"),
            "Bounty::redeemBounty: callback failed"
        );
        require(
            IERC721(nftContract).ownerOf(nftTokenID) == address(this),
            "Bounty::redeemBounty: NFT not delivered"
        );
        emit Acquired(_amount);
    }

    // @notice Kicks off fractionalization once the NFT is acquired
    // @dev Also triggered by the first claim()
    function fractionalize() external nonReentrant {
        require(
            status() == BountyStatus.ACQUIRED,
            "Bounty::fractionalize: NFT not yet acquired"
        );
        _fractionalizeNFTIfNeeded();
    }

    // @notice Claims any tokens or eth for `_contributor` from active or expired bounties
    // @dev msg.sender does not necessarily match `_contributor`
    // @dev O(N) where N = number of contributions by `_contributor`
    // @param _contributor The address of the contributor to claim tokens for
    function claim(address _contributor) external nonReentrant {
        BountyStatus _status = status();
        require(
            _status != BountyStatus.ACTIVE,
            "Bounty::claim: bounty still active"
        );
        require(
            totalContributedByAddress[_contributor] != 0,
            "Bounty::claim: not a contributor"
        );
        require(
            !claimed[_contributor],
            "Bounty::claim: bounty already claimed"
        );
        claimed[_contributor] = true;

        if (_status == BountyStatus.ACQUIRED) {
            _fractionalizeNFTIfNeeded();
        }

        (uint256 _tokenAmount, uint256 _ethAmount) = claimAmounts(_contributor);

        if (_ethAmount > 0) {
            _transferETH(_contributor, _ethAmount);
        }
        if (_tokenAmount > 0) {
            _transferTokens(_contributor, _tokenAmount);
        }
        emit Claimed(_contributor, _tokenAmount, _ethAmount);
    }

    // @notice (GOV ONLY) emergency: withdraw stuck ETH
    function emergencyWithdrawETH(uint256 _value) external onlyGov {
        _transferETH(gov, _value);
    }

    // @notice (GOV ONLY) emergency: execute arbitrary calls from contract
    function emergencyCall(address _contract, bytes memory _calldata)
        external
        onlyGov
        returns (bool _success, bytes memory _returnData)
    {
        (_success, _returnData) = _contract.call(_calldata);
        require(_success, string(_returnData));
    }

    // @notice (GOV ONLY) emergency: immediately expires bounty
    function emergencyExpire() external onlyGov {
        expiryTimestamp = block.timestamp;
    }

    // @notice The amount of tokens and ETH that can or have been claimed by `_contributor`
    // @dev Check `claimed(address)` to see if already claimed
    // @param _contributor The address of the contributor to compute amounts for.
    function claimAmounts(address _contributor)
        public
        view
        returns (uint256 _tokenAmount, uint256 _ethAmount)
    {
        require(
            status() != BountyStatus.ACTIVE,
            "Bounty::claimAmounts: bounty still active"
        );
        if (totalSpent > 0) {
            uint256 _ethUsed = ethUsedForAcquisition(_contributor);
            if (_ethUsed > 0) {
                _tokenAmount = valueToTokens(_ethUsed);
            }
            _ethAmount = totalContributedByAddress[_contributor] - _ethUsed;
        } else {
            _ethAmount = totalContributedByAddress[_contributor];
        }
    }

    // @notice The amount of the contributor's ETH used to acquire the NFT
    // @notice Tokens owed will be proportional to eth used.
    // @notice ETH contributed = ETH used in acq + ETH left to be claimed
    // @param _contributor The address of the contributor to compute eth usd
    function ethUsedForAcquisition(address _contributor)
        public
        view
        returns (uint256 _total)
    {
        require(
            totalSpent > 0,
            "Bounty::ethUsedForAcquisition: NFT not acquired yet"
        );
        // load from storage once and reuse
        uint256 _totalSpent = totalSpent;
        Contribution[] memory _contributions = contributions[_contributor];
        for (uint256 _i = 0; _i < _contributions.length; _i++) {
            Contribution memory _contribution = _contributions[_i];
            if (
                _contribution.priorTotalContributed + _contribution.amount <=
                _totalSpent
            ) {
                _total = _total + _contribution.amount;
            } else if (_contribution.priorTotalContributed < _totalSpent) {
                uint256 _amountUsed = _totalSpent -
                    _contribution.priorTotalContributed;
                _total = _total + _amountUsed;
                break;
            } else {
                break;
            }
        }
    }

    // @notice Computes the status of the bounty
    // Valid state transitions:
    // EXPIRED
    // ACTIVE -> EXPIRED
    // ACTIVE -> ACQUIRED
    function status() public view returns (BountyStatus) {
        if (totalSpent > 0) {
            return BountyStatus.ACQUIRED;
        } else if (block.timestamp >= expiryTimestamp) {
            return BountyStatus.EXPIRED;
        } else {
            return BountyStatus.ACTIVE;
        }
    }

    // @dev Helper function for translating ETH contributions into token amounts
    function valueToTokens(uint256 _value)
        public
        pure
        returns (uint256 _tokens)
    {
        _tokens = _value * TOKEN_SCALE;
    }

    function _transferETH(address _to, uint256 _value) internal {
        // guard against rounding errors
        uint256 _balance = address(this).balance;
        if (_value > _balance) {
            _value = _balance;
        }
        payable(_to).transfer(_value);
    }

    function _transferTokens(address _to, uint256 _value) internal {
        // guard against rounding errors
        uint256 _balance = tokenVault.balanceOf(address(this));
        if (_value > _balance) {
            _value = _balance;
        }
        tokenVault.transfer(_to, _value);
    }

    function _fractionalizeNFTIfNeeded() internal {
        if (address(tokenVault) != address(0)) {
            return;
        }
        IERC721(nftContract).approve(address(tokenVaultFactory), nftTokenID);
        uint256 _vaultNumber = tokenVaultFactory.mint(
            name,
            symbol,
            address(nftContract),
            nftTokenID,
            valueToTokens(totalSpent),
            totalSpent * RESALE_MULTIPLIER,
            0 // fees
        );
        tokenVault = ITokenVault(tokenVaultFactory.vaults(_vaultNumber));
        tokenVault.updateCurator(address(0));
    }
}
