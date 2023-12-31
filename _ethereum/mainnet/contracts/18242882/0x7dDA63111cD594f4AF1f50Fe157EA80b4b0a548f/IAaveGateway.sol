//SPDX-License-Identifier: UNLICENSED

interface IAaveGateway {
    function depositETH(
        address,
        address onBehalfOf,
        uint16 referralCode
    ) external payable;
}
