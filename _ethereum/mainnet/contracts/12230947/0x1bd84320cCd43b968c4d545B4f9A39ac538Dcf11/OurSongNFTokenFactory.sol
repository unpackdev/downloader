// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Context.sol";
import "./OurSongNFToken.sol";

contract OurSongNFTokenFactory is Context {

    address private _ourAdminAddress;

    event LogCreateContract(address indexed sender, address indexed newContract);

    constructor(address ourAdminAddress_) public {
        _ourAdminAddress = ourAdminAddress_;
    }

    function createOurSongNFToken(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        string memory contractURI_
    )
        external
        returns(address)
    {
        OurSongNFToken newTokenContract = new OurSongNFToken(name_, symbol_, baseURI_);
        newTokenContract.setContractURI(contractURI_);
        newTokenContract.transferOwnership(_ourAdminAddress);
        address newTokenContractAddress = address(newTokenContract);
        emit LogCreateContract(_msgSender(), newTokenContractAddress);
        return newTokenContractAddress;
    }

    function ourAdmin() public view virtual returns (address) {
        return _ourAdminAddress;
    }
}