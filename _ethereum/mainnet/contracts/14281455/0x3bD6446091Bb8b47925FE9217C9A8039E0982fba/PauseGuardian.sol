pragma solidity ^0.5.16;

import "./Ownable.sol";

interface IComptroller {
    function getAllMarkets() external returns (address[] memory);
    function _setMintPaused(address cToken, bool state) external returns (bool);
    function _setBorrowPaused(address cToken, bool state) external returns (bool);
    function _setTransferPaused(bool state) external returns (bool);
    function _setSeizePaused(bool state) external returns (bool);
}
contract PauseGuardian is Ownable {
    IComptroller public Comptroller;

    constructor(IComptroller comptroller) public {
        Comptroller = comptroller;
    }

    function pauseAll() external onlyOwner {
        address[] memory markets = Comptroller.getAllMarkets();
        for (uint i = 0; i < markets.length; i++) {
            Comptroller._setMintPaused(markets[i], true);
            Comptroller._setBorrowPaused(markets[i], true);
        }
        Comptroller._setTransferPaused(true);
        Comptroller._setSeizePaused(true);
    }

    function setMintPaused(address cToken) external onlyOwner {
        Comptroller._setMintPaused(cToken, true);
    }

    function setBorrowPaused(address cToken) external onlyOwner {
        Comptroller._setBorrowPaused(cToken, true);
    }

    function pauseAllMints() external onlyOwner {
        address[] memory markets = Comptroller.getAllMarkets();
        for (uint i = 0; i < markets.length; i++) {
            Comptroller._setMintPaused(markets[i], true);
        }
    }

    function pauseAllBorrows() external onlyOwner {
        address[] memory markets = Comptroller.getAllMarkets();
        for (uint i = 0; i < markets.length; i++) {
            Comptroller._setBorrowPaused(markets[i], true);
        }
    }

    function setTransferPaused() external onlyOwner {
        Comptroller._setTransferPaused(true);
    }

    function setSeizePaused() external onlyOwner {
        Comptroller._setSeizePaused(true);
    }

    function setComptroller(IComptroller comptroller) external onlyOwner {
        Comptroller = comptroller;
    }
}