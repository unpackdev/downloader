// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;


interface ISynth {
    // Views
    function currencyKey() external view returns (bytes32);

    function transferableSynths(address account) external view returns (uint);

    // Mutative functions
    function transferAndSettle(address to, uint value) external returns (bool);

    function transferFromAndSettle(
        address from,
        address to,
        uint value
    ) external returns (bool);

    // Restricted: used internally to Elysian
    function burn(address account, uint amount) external;

    function issue(address account, uint amount) external;
}
