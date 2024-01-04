pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface ListInterface {
    function accounts() external view returns (uint64);
    function accountAddr(uint64) external view returns (address);
}

contract InstaDSAPowerResolver {
    function getTotalAccounts() public view returns(uint totalAccounts) {
        ListInterface list = ListInterface(0x4c8a1BEb8a87765788946D6B19C6C6355194AbEb);
        totalAccounts = uint(list.accounts());
    }

    function getDSAWallets(uint start, uint end) public view returns(address[] memory) {
        assert(start < end);
        ListInterface list = ListInterface(0x4c8a1BEb8a87765788946D6B19C6C6355194AbEb);
        uint totalAccounts = uint(list.accounts());
        end = totalAccounts < end ? totalAccounts : end;
        uint len = (end - start);
        address[] memory wallets = new address[](len);
        for (uint i = 0; i <= len; i++) {
            wallets[i] = list.accountAddr(uint64(start + i));
        }
        return wallets;
    }
}