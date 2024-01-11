//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./console.sol";

contract DividendTracker is Ownable {
    using SafeMath for uint256;

    address private marketingWallet;

    address public saitamaMarketingWallet;
    address public cmsnMarketingWallet;
    address public burnerWallet;

    uint256 public saitamaPercentage = 6666; // 66.66%
    uint256 public cmsnPercentage = 1668; // 16.68%
    uint256 public burnerPercentage = 1666; // 16.66%

    uint256 public constant TOTAL_PERCENTAGE = 10000; // 100%

    event PercentagesSet(
        uint256 _saitamaPercentage,
        uint256 _cmsnPercentage,
        uint256 _burnerPercentage
    );
    event WalletsSet(
        address indexed _saitamaWallet,
        address indexed _cmsnWallet,
        address indexed _burnerWallet
    );
    event Withdraw(
        uint256 _saitamaAmount,
        uint256 _cmsnAmount,
        uint256 _burnerAmount
    );

    constructor(address _marketingWallet) {
        marketingWallet = _marketingWallet;

        saitamaMarketingWallet = 0xff370498864E173413C752e680366b612BEf27f5;
        cmsnMarketingWallet = 0x86Fc52506b40AC87b9A449C868B97145ead2842d;
        burnerWallet = 0x174dC5473FF69055dE5165Ba4F336b6c2CA2f5B4;
    }

    receive() external payable {
        if (msg.sender == marketingWallet) {
            withdraw();
        }
    }

    fallback() external payable {
        if (msg.sender == marketingWallet) {
            withdraw();
        }
    }

    /// @dev Set the percentage for Saitama and The Commission's marketing wallet
    /// @param _saitamaPercentage Saitama's percentage for marketing wallet
    /// @param _cmsnPercentage The Commission's percentage for marketing wallet
    /// @param _burnerPercentage The Commission's percentage for marketing wallet
    function setPercentages(
        uint256 _saitamaPercentage,
        uint256 _cmsnPercentage,
        uint256 _burnerPercentage
    ) external onlyOwner {
        require(
            _saitamaPercentage + _cmsnPercentage + _burnerPercentage ==
                TOTAL_PERCENTAGE,
            "DividendTracker: invalid percentage"
        );

        saitamaPercentage = _saitamaPercentage;
        cmsnPercentage = _cmsnPercentage;
        burnerPercentage = _burnerPercentage;

        emit PercentagesSet(
            saitamaPercentage,
            cmsnPercentage,
            _burnerPercentage
        );
    }

    /// @dev Set the marketing wallet addresses for Saitama and The Commission
    /// @param _saitamaWallet Saitama's marketing wallet address
    /// @param _cmsnWallet The Commission's marketing wallet address
    /// @param _burnerWallet The Commission's marketing wallet address
    function setWallets(
        address _saitamaWallet,
        address _cmsnWallet,
        address _burnerWallet
    ) external onlyOwner {
        require(
            _saitamaWallet != address(0),
            "DividendTracker: invalid Saitama address"
        );
        require(
            _cmsnWallet != address(0),
            "DividendTracker: invalid Commission address"
        );
        require(
            _burnerWallet != address(0),
            "DividendTracker: invalid Burner address"
        );

        saitamaMarketingWallet = _saitamaWallet;
        cmsnMarketingWallet = _cmsnWallet;
        burnerWallet = _burnerWallet;

        emit WalletsSet(
            saitamaMarketingWallet,
            cmsnMarketingWallet,
            burnerWallet
        );
    }

    function withdraw() private {
        uint256 balance = address(this).balance;
        uint256 saitamaAmount = balance.mul(saitamaPercentage).div(
            TOTAL_PERCENTAGE
        );
        uint256 burnerAmount = balance.mul(burnerPercentage).div(
            TOTAL_PERCENTAGE
        );
        uint256 cmsnAmount = balance.sub(saitamaAmount).sub(burnerAmount);

        require(saitamaAmount > 0, "DividendTracker: not enough amount");
        require(burnerAmount > 0, "DividendTracker: not enough amount");
        require(cmsnAmount > 0, "DividendTracker: not enough amount");

        (bool sent, ) = payable(saitamaMarketingWallet).call{
            value: saitamaAmount
        }("");
        require(sent, "DividendTracker: transfer failed to Saitama's wallet");

        (sent, ) = payable(burnerWallet).call{value: burnerAmount}("");
        require(sent, "DividendTracker: transfer failed to Burner's wallet");

        (sent, ) = payable(cmsnMarketingWallet).call{value: cmsnAmount}("");
        require(sent, "DividendTracker: transfer failed");

        emit Withdraw(saitamaAmount, cmsnAmount, burnerAmount);
    }
}
