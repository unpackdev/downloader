// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ECDSA.sol";
import "./IERC20.sol";
import "./Withdrawable.sol";

interface IDeposit {
    function transferFrom(
        address _assetContract,
        address _from,
        address _to,
        uint256 _tokenId
    ) external;
}

contract STDAuctionV1 is Withdrawable {

    address public deposit;
    address public erc20;

    constructor(address _deposit, address _erc20) {
        setDeposit(_deposit);
        setErc20(_erc20);
    }

    function setDeposit(address _deposit) public onlyOperator() {
        deposit = _deposit;
    }

    function setErc20(address _erc20) public onlyOperator() {
        erc20 = _erc20;
    }

    function successBid(
        address _signer,
        address _erc721,
        uint256 _tokenId,
        address _erc20,
        uint256 _value,
        uint256 _deadline,
        bytes memory _signature
    ) external onlyOperator() {
        require(_deadline > block.timestamp, "expired");
        require(_erc20 == erc20, "must be allowed erc20");
        require(IERC20(_erc20).allowance(_signer, address(this)) >= _value, "must be approved");
        require(IERC20(_erc20).balanceOf(_signer) >= _value, "lack of weth");

        require(
            validateSig(
                _signer,
                _erc721,
                _tokenId,
                _erc20,
                _value,
                _deadline,
                _signature
            ),
            "invalid signature"
        );

        // このコントラクトにデポジット
        IERC20(_erc20).transferFrom(_signer, address(this), _value);

        // NFTのdepositコントラクトから配る
        IDeposit(deposit).transferFrom(_erc721, deposit, _signer, _tokenId);
    }

    function validateSig(
        address _signer,
        address _erc721,
        uint256 _tokenId,
        address _erc20,
        uint256 _value,
        uint256 _deadline,
        bytes memory _signature
    ) public pure returns (bool) {
        address signer = ECDSA.recover(
            ECDSA.toEthSignedMessageHash(encodeData(
                _signer,
                _erc721,
                _tokenId,
                _erc20,
                _value,
                _deadline
            )),
            _signature
        );

        return (signer == _signer);
    }

    function encodeData(
        address _signer,
        address _erc721,
        uint256 _tokenId,
        address _erc20,
        uint256 _value,
        uint256 _deadline
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(
            _signer,
            _erc721,
            _tokenId,
            _erc20,
            _value,
            _deadline
        ));
    }

}
