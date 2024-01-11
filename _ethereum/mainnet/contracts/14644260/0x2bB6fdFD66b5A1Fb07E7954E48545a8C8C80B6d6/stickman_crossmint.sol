// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @author AC

import "./stickman_contract.sol";


contract StickmanCrossmint is Ownable {

    StickmanERC721 stickman_contract;
    function setStickmanContract(StickmanERC721 _contract) external onlyOwner {
        stickman_contract = _contract;
    }

    address public _crossmint_address;
    function setCrossmintAddress(address _crossmint) external onlyOwner {
        _crossmint_address = _crossmint;
    }
    modifier onlyCrossmint {
        require (msg.sender == _crossmint_address);
        _;
    }


    function crossmintMint(address to, uint256 _count) external payable onlyCrossmint {
        stickman_contract.crossmintTo(to, _count);
    }


    /** developer payment */

    address payable constant A = payable(0xAd75E32b0603D4a2b7E89A23eDD3228E5cD0699A); /** TODO set this to the atc address */
    address payable constant T = payable(0xAECE4959fa2e70e9210D6755B25F73A225C4F956); /** TODO set this to the atc address */
    address payable constant C = payable(0x0E25e1A23378ece3C304b930b5B42727E6D249F9); /** TODO set this to the atc address */
    address payable constant O = payable(0x24BDa462ad1C29D8f0b31e266ccF259fE305fAd1);
    function disburse() external onlyOwner {
        uint256 total = address(this).balance;

        uint256 ATC = (total * 8) / 100;
        A.transfer(ATC / 3);
        T.transfer(ATC / 3);
        C.transfer(ATC / 3);

        payable(O).transfer(total - ((total * 8) / 100));
    }

}