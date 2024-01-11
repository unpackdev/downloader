// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.7;

import "./ONFT721.sol";
import "./IChainLinkOracle.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

/// @title Interface of the UniversalONFT standard
contract UniversalONFT721 is ONFT721 {
    using SafeERC20 for IERC20;
    IERC20 APE = IERC20(0x4d224452801ACEd8B2F0aebE155379bb5D594381);
    IChainLinkOracle APEUSDOracle = IChainLinkOracle(0xD10aBbC76679a20055E167BB80A24ac851b37056);
    IChainLinkOracle ETHUSDOracle = IChainLinkOracle(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

    uint public startTime;
    uint public endTime;
    uint public nextMintId;
    uint public publicMints;
    uint public maxPublicMints;
    uint public mintPrice;

    /// @notice Constructor for the UniversalONFT
    /// @param _name the name of the token
    /// @param _symbol the token symbol
    /// @param _layerZeroEndpoint handles message transmission across chains
    /// @param _startMintId starting mint ID for cross chain compatibility
    /// @param _maxPublicMints the max number of public sale mints on this chain
    /// @param _mintPrice price per mint in ETH
    constructor(
      string memory _name,
      string memory _symbol,
      address _layerZeroEndpoint,
      uint _startMintId,
      uint _maxPublicMints,
      uint _mintPrice
    ) ONFT721(_name, _symbol, _layerZeroEndpoint) {
        maxPublicMints = _maxPublicMints;
        nextMintId = _startMintId;
        mintPrice = _mintPrice;
    }

    /// @notice Get mint price in APE
    function mintPriceInApe() public returns (uint256) {
        uint256 ETHUSD = ETHUSDOracle.latestAnswer();
        uint256 APEUSD = APEUSDOracle.latestAnswer();

        return mintPrice * ETHUSD / APEUSD;
    }

    /// @notice Mint your ONFT using ETH
    function mint(uint256 number) external payable {
        require(block.chainid == 1, "Invalid chain id");
        require(block.timestamp > startTime && block.timestamp < endTime, "Not open");
        require(publicMints + number - 1 <= maxPublicMints, "ONFT: Max Mint limit reached");
        require(msg.value >= mintPrice * number, "Insufficient ETH sent for mint");

        publicMints += number;

        uint256 newId;

        for (uint i = 0; i < number; ++i) {
            newId = nextMintId;
            nextMintId++;
            _safeMint(msg.sender, newId);
        }
    }

    /// @notice Mint your 0NFT using APE
    function mintWithAPE(uint256 number) external payable {
        require(block.chainid == 1, "Invalid chain id");
        require(block.timestamp > startTime && block.timestamp < endTime, "Not open");
        require(publicMints + number - 1 <= maxPublicMints, "ONFT: Max Mint limit reached");
        require(APE.transferFrom(msg.sender, address(this), mintPriceInApe() * number));

        publicMints += number;

        uint256 newId;

        for (uint i = 0; i < number; ++i) {
            newId = nextMintId;
            nextMintId++;
            _safeMint(msg.sender, newId);
        }
    }

    /// @notice Mint admin NFTs
    function adminMint(uint number) external onlyOwner {
      uint256 newId;
      for (uint i = 0; i < number; ++i) {
        newId = nextMintId;
        nextMintId++;
        _safeMint(msg.sender, newId);
      }
    }

    /// @notice Withdraw
    function adminWithdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    /// @notice Withdraw APE
    function adminWithdrawAPE() external onlyOwner {
        APE.safeTransfer(msg.sender, APE.balanceOf(address(this)));
    }

    /// @notice Set startTime
    function adminSetStartTime(uint time) external onlyOwner {
        startTime = time;
    }

    /// @notice Set endTime
    function adminSetEndTime(uint time) external onlyOwner {
        endTime = time;
    }
}