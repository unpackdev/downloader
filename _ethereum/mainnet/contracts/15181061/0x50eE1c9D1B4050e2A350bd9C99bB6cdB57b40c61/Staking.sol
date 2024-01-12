// Github source: https://github.com/alexanderem49/wildwestnft-smart-contracts
//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./GoldenNugget.sol";
import "./ITokenSupplyData.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./AccessControl.sol";

contract Staking is IERC721Receiver, AccessControl {
    GoldenNugget public goldenNugget;

    mapping(address => mapping(uint256 => address)) public tokenOwner;
    mapping(address => Stake) private stakeInfo;
    mapping(address => Nft) public nftInfo;

    enum Status {
        NOT_ACTIVE,
        ACTIVE,
        WAIT
    }

    struct Stake {
        uint128 tokenCount;
        uint128 startDate;
    }

    struct Nft {
        uint8 percentageThreshold;
        uint8 status;
    }

    event NftAdded(address indexed _nftContract);

    event Claim(address indexed _user, uint256 _payoutAmount);

    event ERC721Received(
        uint256 indexed _nftId,
        address indexed _nftContract,
        address indexed _from
    );

    event Withdraw(
        uint256 indexed _nftId,
        address indexed _nftContract,
        address indexed _to
    );

    constructor(GoldenNugget goldenNugget_) {
        goldenNugget = goldenNugget_;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @notice Checks if NFT is transferred to a contract.
     * @param _from The user address.
     * @param _tokenId The token id of collection NFT.
     * @return Selector To confirm the token transfer.
     */
    function onERC721Received(
        address,
        address _from,
        uint256 _tokenId,
        bytes calldata
    ) external virtual override returns (bytes4) {
        Nft storage nft = nftInfo[msg.sender];

        // Updates the status to active if percentage threshold is reached.
        if (nft.status == uint8(Status.WAIT)) {
            if (isReachedThreshold(msg.sender, nft.percentageThreshold)) {
                nft.status = uint8(Status.ACTIVE);
            }
        }

        require(nft.status == uint8(Status.ACTIVE), "Staking: not started");
        // Gives available amount of Golden Nuggets.
        _claim(_from);

        Stake storage stake = stakeInfo[_from];
        // Increases the number of staked tokens.
        stake.tokenCount++;
        // Updates the start date for the next payout calculation.
        stake.startDate = uint128(block.timestamp);

        tokenOwner[msg.sender][_tokenId] = _from;

        emit ERC721Received(_tokenId, msg.sender, _from);

        return this.onERC721Received.selector;
    }

    /**
     * @notice Registers NFT contract and sets circulating supply percentage threshold when staking becomes active.
     * @param _nft The NFT contract.
     * @param _percentageThreshold The percentage threshold.
     */
    function addNFT(address _nft, uint8 _percentageThreshold)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            nftInfo[_nft].status == uint8(Status.NOT_ACTIVE),
            "Staking: already added"
        );

        // Staking should only start when circulating supply percentage is above percentage threshold.
        nftInfo[_nft].status = isReachedThreshold(_nft, _percentageThreshold)
            ? uint8(Status.ACTIVE)
            : uint8(Status.WAIT);

        nftInfo[_nft].percentageThreshold = _percentageThreshold;

        emit NftAdded(_nft);
    }

    /**
     * @notice Gives available amount of Golden Nuggets from staking.
     */
    function claim() external {
        _claim(msg.sender);
    }

    /**
     * @notice Withdraws token NFT and gives available amount of Golden Nuggets from staking.
     * @param _nftId The token id of collection NFT.
     * @param _nft The NFT contract.
     */
    function withdrawNft(uint256 _nftId, address _nft) external {
        require(
            tokenOwner[_nft][_nftId] == msg.sender,
            "Staking: not owner NFT"
        );

        // Gives available amount of Golden Nuggets.
        _claim(msg.sender);
        // Decreases the number of staked tokens.
        stakeInfo[msg.sender].tokenCount--;

        delete tokenOwner[_nft][_nftId];
        // Transfers token by id from staking contract to owner nft.
        IERC721(_nft).safeTransferFrom(address(this), msg.sender, _nftId);

        emit Withdraw(_nftId, _nft, msg.sender);
    }

    /**
     * @notice Checks if staking for specified collection NFT is available.
     * @param _nft The NFT contract.
     * @return Status If staking is available or not.
     */
    function isActive(address _nft) external view returns (bool) {
        Nft memory nft = nftInfo[_nft];
        uint8 status = nft.status;

        // Percentage threshold is already reached.
        if (status == uint8(Status.ACTIVE)) {
            return true;
        }
        // NFT contract doesn't register.
        if (status == uint8(Status.NOT_ACTIVE)) {
            return false;
        }

        return isReachedThreshold(_nft, nft.percentageThreshold);
    }

    /**
     * @notice Gets staking information.
     * @param _user The user address.
     * @return tokenCount The token count of staking.
     * @return startDate The start date of staking.
     * @return payoutAmount The available amount of Golden Nuggets from staking nft.
     */
    function getStakerInfo(address _user)
        external
        view
        returns (
            uint128 tokenCount,
            uint128 startDate,
            uint256 payoutAmount
        )
    {
        Stake memory stake = stakeInfo[_user];

        uint128 tokenCount_ = stake.tokenCount;
        uint128 startDate_ = stake.startDate;
        uint256 payoutAmount_ = getPayoutAmount(startDate_, tokenCount_);

        return (tokenCount_, startDate_, payoutAmount_);
    }

    /**
     * @notice Checks if percentage threshold is reached or not.
     * @param _nft The NFT contract.
     * @return Status If threshold is reached or not.
     */
    function isReachedThreshold(address _nft, uint8 _percentage)
        private
        view
        returns (bool)
    {
        ITokenSupplyData token = ITokenSupplyData(_nft);

        return
            (token.circulatingSupply() * 100) / token.maxSupply() >=
            _percentage;
    }

    /**
     * @notice Gives available amount of Golden Nuggets for specific user.
     * @param _to The user address.
     */
    function _claim(address _to) private {
        Stake storage stake = stakeInfo[_to];
        uint128 startDate = stake.startDate;

        if (startDate == 0) {
            return;
        }
        // Returns available amount of Golden Nuggets to claim.
        uint256 payoutAmount = getPayoutAmount(startDate, stake.tokenCount);
        // Updates the start date for the next payout calculation.
        stake.startDate = uint128(block.timestamp);
        // Payout of tokens for staking.
        goldenNugget.mint(_to, payoutAmount);

        emit Claim(_to, payoutAmount);
    }

    /**
     * @notice Returns available amount of Golden Nuggets from staking nft.
     * @param _startDate The start date of staking.
     * @param _tokenCount The token count of staking.
     */
    function getPayoutAmount(uint128 _startDate, uint128 _tokenCount)
        private
        view
        returns (uint256)
    {
        return (block.timestamp - _startDate) * _tokenCount * 1653439153935; // 10**18/60*60*24*7.
    }
}
