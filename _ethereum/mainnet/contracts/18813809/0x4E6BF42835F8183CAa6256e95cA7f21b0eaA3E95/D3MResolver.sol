// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

interface IVat {
    function urns(bytes32, address) external view returns (uint256, uint256);
}

interface ID3MHub {
    function vat() external view returns (IVat);
    function pool(bytes32) external view returns (address);
    function exec(bytes32) external;
}

contract D3MResolver {

    IVat public immutable vat;
    ID3MHub public immutable hub;
    bytes32 public immutable ilk;
    uint256 public immutable threshold;

    constructor(address _hub, bytes32 _ilk, uint256 _threshold) {
        hub = ID3MHub(_hub);
        vat = hub.vat();
        ilk = _ilk;
        threshold = _threshold;
    }

    function checker()
        external
        returns (bool canExec, bytes memory execPayload)
    {
        address pool = hub.pool(ilk);
        (, uint256 part) = vat.urns(ilk, pool);

        hub.exec(ilk);

        (, uint256 nart) = vat.urns(ilk, pool);

        canExec = nart >= part + threshold;
        
        execPayload = abi.encodeCall(ID3MHub.exec, (ilk));
    }

}
