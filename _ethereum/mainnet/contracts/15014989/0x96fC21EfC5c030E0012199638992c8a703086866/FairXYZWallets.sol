// SPDX-License-Identifier: MIT
// @ Fair.xyz dev

pragma solidity 0.8.7;

import "Ownable.sol";

contract FairXYZWallets is Ownable{
    
    address internal signerAddress;

    address internal withdrawAddress;

    mapping(address => bool) internal preApprovedAddresses;

    mapping(string => string) internal URIReveal; 

    mapping(string => bool) internal lockedURIReveal;

    event NewSignerWallet(address indexed newSignerAddress);
    event NewWithdrawWallet(address indexed newWithdrawAddress);

    constructor(address addressForSigner, address addressForWithdraw, address[] memory preApprovedList){
        
        require(preApprovedList.length <= 5, "Cannot set too many pre-approved addresses!");
        require(addressForSigner != address(0), "Cannot be zero address");
        require(addressForWithdraw != address(0), "Cannot be zero address");

        signerAddress = addressForSigner;
        withdrawAddress = addressForWithdraw;

        for(uint i = 0; i < preApprovedList.length; )
        {
            addPreapproved(preApprovedList[i]);
            ++i;
        }
    }

    function viewPathURI(string memory pathURI) view external returns(string memory) 
    {
        return URIReveal[pathURI];
    }

    function viewSigner() view external returns(address)
    {
        return(signerAddress);
    }

    function viewWithdraw() view external returns(address)
    {
        return(withdrawAddress);
    }

    function revealPathURI(string memory pathURI, string memory revealURI) external onlyOwner returns(string memory)
    {
        require(!lockedURIReveal[pathURI], "Path URI has been locked!");
        URIReveal[pathURI] = revealURI;
        return(revealURI);
    }

    function lockURIReveal(string memory pathURI) external onlyOwner
    {
        require(!lockedURIReveal[pathURI], "Path URI has been locked!");
        lockedURIReveal[pathURI] = true;
    }

    function changeSigner(address newAddress) external onlyOwner returns(address)
    {
        signerAddress = newAddress;
        emit NewSignerWallet(signerAddress);
        return signerAddress;
    }

    function changeWithdraw(address newAddress) external onlyOwner returns(address)
    {
        withdrawAddress = newAddress;
        emit NewWithdrawWallet(signerAddress);
        return withdrawAddress;
    }

    function viewPreapproved(address address_) external view returns(bool)
    {
        return preApprovedAddresses[address_];
    }

    // Gas-free listings on OpenSea and LooksRare. Can only be called from constructor
    function addPreapproved(address preapprovedAddress) private onlyOwner returns(address)
    {
        require(preapprovedAddress != address(0), "Cannot be zero address");
        preApprovedAddresses[preapprovedAddress] = true;
        return preapprovedAddress;
    }

    function removePreapproved(address preapprovedAddress) external onlyOwner returns(address)
    {
        require(preApprovedAddresses[preapprovedAddress]);
        preApprovedAddresses[preapprovedAddress] = false;
        return(preapprovedAddress);
    }


}