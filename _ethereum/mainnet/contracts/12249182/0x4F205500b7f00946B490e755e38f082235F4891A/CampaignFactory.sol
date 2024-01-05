// SPDX-License-Identifier: MIT
pragma solidity 0.7.1;

import "./ICampaign.sol";
import "./Campaign.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./Initializable.sol";
import "./SafeMath.sol";

contract CampaignFactory is Ownable, Pausable, Initializable {
    // Percentage of platform fee
    uint256 public platformFeeRate;
    // Address of platform revenue. Platform fee will transfer to it
    address public platformRevenueAddress;
    // Array of created Campaign Address
    address[] public allCampaigns;
    // Mapping from User token. From tokens to array of created Campaign for token
    mapping(address => mapping(IERC20 => address[])) public getCampaigns;

    event IcoCampaignCreated(
        address registedBy,
        address indexed token,
        address indexed campaign,
        uint256 campaignId
    );
    event PlatformFeeChanged(address changer, uint256 fee);
    event PlatformRevenueAddressChanged(
        address changer,
        address newRevenueAddress
    );

    function initialize(uint256 _platformFeeRate, address _revenueAddress)
        public
        initializer
    {
        require(_revenueAddress != address(0), "ICOFactory::ZERO_ADDRESS");
        require(_platformFeeRate >= 0, "ICOFactory::NEGATIVE_FEE");
        require(_platformFeeRate < 100, "ICOFactory::OVERFLOW_FEE");
        platformFeeRate = _platformFeeRate;
        platformRevenueAddress = _revenueAddress;
        paused = false;
        owner = msg.sender;

        emit PlatformFeeChanged(msg.sender, _platformFeeRate);
    }

    /**
     * @notice Get platform fee in percent
     * @dev Created campaign call this function for get platform fee
     * @return Return number of platform fee
     */
    function getPlatformFeeRate() public view returns (uint256) {
        return platformFeeRate;
    }

    /**
     * @notice Get platform revenue address
     * @dev All of platform fee will transfer to this address
     * @return Address of Platform Vault
     */
    function getplatformRevenueAddress() public view returns (address) {
        return platformRevenueAddress;
    }

    /**
     * @notice Get the number of all created campaigns
     * @return Return number of created campaigns
     */
    function allCampaignsLength() public view returns (uint256) {
        return allCampaigns.length;
    }

    /**
     * @notice Get the created campaigns by token address
     * @dev User can retrieve their created campaign by address of tokens
     * @param _creator Address of created campaign user
     * @param _token Address of token want to query
     * @return Created Campaign Address
     */
    function getCreatedCampaignsByToken(address _creator, IERC20 _token)
        public
        view
        returns (address[] memory)
    {
        return getCampaigns[_creator][_token];
    }

    /**
     * @notice Retrieve number of campaigns created for specific token
     * @param _creator Address of created campaign user
     * @param _token Address of token want to query
     * @return Return number of created campaign
     */
    function getCreatedCampaignsLengthByToken(address _creator, IERC20 _token)
        public
        view
        returns (uint256)
    {
        return getCampaigns[_creator][_token].length;
    }

    /**
     * @notice Owner can set the platform fee
     * @dev Campaign will call function for distribute platform fee
     * @param _fee new fee percentage number
     */
    function setPlatformFeeRate(uint256 _fee)
        external
        onlyOwner
        returns (uint256)
    {
        require(_fee >= 0, "ICOFactory::NEGATIVE_FEE");
        require(_fee < 100, "ICOFactory::OVERFLOW_FEE");
        platformFeeRate = _fee;

        emit PlatformFeeChanged(msg.sender, _fee);
    }

    /**
     * @notice Owner can set the platform revenue address
     * @dev Distribution will be transfer to this address
     * @param _revenueAddress new fee percentage number
     */
    function setPlatformRevenueAddress(address _revenueAddress)
        external
        onlyOwner
        returns (uint256)
    {
        require(_revenueAddress != address(0), "ICOFactory::ZERO_ADDRESS");
        platformRevenueAddress = _revenueAddress;

        emit PlatformRevenueAddressChanged(msg.sender, _revenueAddress);
    }

    /**
     * @notice Register ICO Campaign for tokens
     * @dev To register, you MUST have an ERC20 token
     * @param _name String name of new campaign
     * @param _token address of ERC20 token
     * @param _duration Number of ICO time in seconds
     * @param _openTime Number of start ICO time in seconds
     * @param _ethRate Conversion rate for buy token. tokens = value * rate
     * @param _wallet Address of funding ICO wallets. Sold tokens in eth will transfer to this address
     */
    function registerCampaign(
        string memory _name,
        IERC20 _token,
        uint256 _duration,
        uint256 _openTime,
        uint256 _releaseTime,
        uint256 _ethRate,
        uint256 _ethRateDecimals,
        address _wallet
    ) external whenNotPaused returns (address campaign) {
        require(_token != IERC20(address(0)), "ICOFactory::ZERO_ADDRESS");
        require(_duration != 0, "ICOFactory::ZERO_DURATION");
        require(_releaseTime >= block.timestamp, "ICO_CAMPAIGN::INVALID_TIME");
        require(_wallet != address(0), "ICOFactory::ZERO_ADDRESS");
        require(_ethRate != 0, "ICOFactory::ZERO_ETH_RATE");
        bytes memory bytecode = type(Campaign).creationCode;
        uint256 tokenIndex =
            getCreatedCampaignsLengthByToken(msg.sender, _token);
        bytes32 salt =
            keccak256(abi.encodePacked(msg.sender, _token, tokenIndex));
        assembly {
            campaign := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        ICampaign(campaign).initialize(
            _name,
            _token,
            _duration,
            _openTime,
            _releaseTime,
            _ethRate,
            _ethRateDecimals,
            _wallet
        );
        getCampaigns[msg.sender][_token].push(campaign);
        allCampaigns.push(campaign);

        emit IcoCampaignCreated(
            msg.sender,
            address(_token),
            campaign,
            allCampaigns.length - 1
        );
    }
}
