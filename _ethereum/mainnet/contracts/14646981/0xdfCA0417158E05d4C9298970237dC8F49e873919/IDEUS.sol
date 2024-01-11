// SPDX-License-Identifier: GPL-3.0-or-later

interface IDEUS {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function pool_burn_from(address b_address, uint256 b_amount) external;
    function pool_mint(address m_address, uint256 m_amount) external;
    function mint(address to, uint256 amount) external;
    function setDEIAddress(address dei_contract_address) external;
    function setNameAndSymbol(string memory _name, string memory _symbol) external;
}
