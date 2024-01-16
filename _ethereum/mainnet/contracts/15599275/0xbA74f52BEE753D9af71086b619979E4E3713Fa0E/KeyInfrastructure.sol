//SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

contract KeyInfrastructure {
    address internal _root;
    address internal _intermediate;
    address payable internal _issuer;

    event IntermediateRotated(address newKey);
    event IssuerRotated(address newKey);

    modifier onlyRoot() {
        require(msg.sender == _root, "unauthorised: must be root");
        _;
    }

    modifier onlyIntermediate() {
        require(msg.sender == _intermediate, "unauthorised: must be intermediate");
        _;
    }

    modifier onlyIssuer() {
        require(msg.sender == _issuer, "not valid signer");
        _;
    }

    constructor(address root) {
        _root = root;
    }

    function rotateIntermediate(address newIntermediate) public onlyRoot {
        _intermediate = newIntermediate;
        emit IntermediateRotated(newIntermediate);
    }

    function rotateIssuer(address newIssuer) public onlyIntermediate {
        _issuer = payable(newIssuer);
        emit IssuerRotated(newIssuer);
    }

    function getRootKey() public view returns (address) {
        return _root;
    }

    function getIntermediateKey() public view returns (address) {
        return _intermediate;
    }

    function getIssuerKey() public view returns (address) {
        return _issuer;
    }
}
