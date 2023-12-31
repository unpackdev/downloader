

//SPDX-License-Identifier:MIT

pragma solidity ^0.8.4;

abstract contract InsertionSort{
    function insertionSort(uint[] memory a) public pure virtual returns(uint[] memory);
    
}
import "./IERC165.sol";

interface IERC721 is IERC165{
    event Transfer(address indexed from,address indexed to,uint256 indexed tokenId);/*exed是Solidity中的一个关键词。它与事件（Events）和它们的参数一起使用，用来指明哪些参数应该被索引。

在Solidity中，事件是合约与外部监听器之间的一种低级接口。当某些特定的条件或操作发生时，合约可以发出一个事件，外部的应用程序或者前端可以监听和反应这些事件。这是智能合约与外部世界进行交互的常用方式。

indexed的作用是增强事件日志的搜索能力。当你为事件的某个参数加上indexed关键词，这个参数的值就会被处理为一个索引，而不是数据的一部分。这样，外部应用程序可以高效地根据这些索引值搜索特定的日志记录。*/
    event Approval(address indexed owner,address indexed approved,uint256 indexed tokenId);
    event ApprovalAll(address indexed owner,address indexed operator,bool approved);

    function balanceOf(address owner) external view returns(uint256 balance);
    function ownerOf(uint256 tokenId) external view returns(address owner);
    function safeTransferFrom(address from,address to,uint256 tokenId) external;
    function transferFrom(address from,address to,uint256 tokenId) external;
    function approve(address to,uint256 tokenId) external;//tokenId不是关键词，只是一个常用变量名
    function getApproved(uint256 tokenId) external view returns(address operator);//operator是一个操作合约名称，不是关键词
    function setApproveForAll(address operator,bool _approved) external;/*下面是对该函数的解释：函数名：setApproveForAll参数：address operator：这是一个地址类型的参数，通常代表一个外部账户或合约的地址。在这个上下文中，它很可能是指代一个被批准执行某些操作的操作者（operator）。
bool _approved：这是一个布尔型参数，通常表示是否批准上述operator进行某些操作。如果为true，则表示批准；如果为false，则表示不批准。可见性修饰符：external。这意味着这个函数只能从合约外部被调用，不能在合约内部被其他函数调用。从函数的名字和参数来看，这个函数可能与ERC-721或ERC-1155标准相关。在这些标准中，setApproveForAll用于设置或撤销一个操作者对所有代币的操作权限。如果批准，那么这个操作者可以代表代币的所有者转移其代币。*/
    function isApprovedForAll(address owner,address operator) external view returns(bool);
    function safeTransferFrom(address from,address to,uint256 tokenId,bytes calldata data) external;
    /*函数名：safeTransferFrom参数：address from：代币当前的所有者的地址。address to：代币希望转移到的目标地址。这通常是一个外部账户或另一个合约地址。uint256 tokenId：要转移的代币的唯一标识符。在ERC-721标准中，每个代币都有一个唯一的ID，通常表示为tokenId。
bytes calldata data：一个可选的字节数据参数。在使用safeTransferFrom时，这个数据可以被发送到接收合约，允许合约在接收代币时执行额外的逻辑。这是为了增加安全性，确保目标合约知道如何处理接收到的代币。
可见性修饰符：external。这意味着该函数只能从合约外部被调用，不能在合约内部被其他函数调用。这个函数的目的是在确保目标地址to可以安全接收代币的前提下，从from地址安全地转移一个指定的代币（由tokenId表示）。"安全"在此意味着如果目标地址是一个合约，那么那个合约必须实现并确认它可以接收和管理代币。这是为了避免代币被不知道如何处理它们的合约锁定。*/
}

     contract ineractBAYC{
        IERC721 BAYC = IERC721(0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D);
           function balanceOfBAYC(address owner) external view returns (uint256 balance){
        return BAYC.balanceOf(owner);
    }

    // 通过接口调用BAYC的safeTransferFrom()安全转账
    function safeTransferFromBAYC(address from, address to, uint256 tokenId) external{
        BAYC.safeTransferFrom(from, to, tokenId);
    }
}
