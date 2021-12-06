pragma solidity 0.8.0;
pragma abicoder v2;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
contract exchangecur{

    struct reqDetails{
        string currency;
        uint256 fromAmt;
        uint256 toAmt;
        address fromMember;
        bool toToken;
        bool fromToken;
        uint valid;
    }

    struct memDetails{
        uint membership;
        string[] currencies;
        uint[] currencyAmt;
    }

    address token = 0xE14318bDD9fC8DCD43e3Ef5738bAAD5D0DB00dBd;
    address admin;
    mapping(address => reqDetails) requests;
    mapping(address => memDetails) memberDetails;
    address[] memRequested;
    string[] ele;

    modifier onlyAdmin () {
        require(msg.sender==admin);
        _;
    }

    modifier onlyMembers () {
        require(memberDetails[msg.sender].membership == 1);
        _;
    }

    constructor (){
        admin = msg.sender;
    }

    function register () public{
        memberDetails[msg.sender].membership = 1;
    }

    function unRegister () public onlyMembers{
        memberDetails[msg.sender].membership = 0;
    }

    function requestforToken (string memory currency, uint256 fromAmt, uint256 toAmt) public onlyMembers payable{
        for(uint i =0; i < memberDetails[msg.sender].currencies.length; i++){
            if (keccak256(abi.encodePacked(memberDetails[msg.sender].currencies[i])) == keccak256(abi.encodePacked(currency))){
                require(memberDetails[msg.sender].currencyAmt[i] >=  fromAmt, 'Insufficient amount');
                requests[msg.sender].currency = currency;
                requests[msg.sender].fromAmt = fromAmt;
                requests[msg.sender].toAmt = toAmt;
                requests[msg.sender].toToken = true;
                requests[msg.sender].fromToken = false;
                requests[msg.sender].fromMember = msg.sender;
                requests[msg.sender].valid =1;

                int found = 0;
                for(uint j=0; j<memRequested.length; j++){
                    if(memRequested[j] == msg.sender){
                        found = 1;
            }
        }
                if(found == 0){
                    memRequested.push(msg.sender);
                }
            }
        }
    }

    function requestforCur (string memory currency, uint256 fromAmt, uint256 toAmt) public onlyMembers payable{
        ele.push(currency);
        require(ERC20(token).balanceOf(msg.sender) >= fromAmt, "Insufficient Token");
        require(ERC20(token).allowance(msg.sender, address(this)) >= fromAmt, "Insufficient Allowance");

        requests[msg.sender].currency = currency;
        requests[msg.sender].fromAmt = fromAmt;
        requests[msg.sender].toAmt = toAmt;
        requests[msg.sender].toToken = false;
        requests[msg.sender].fromToken = true;
        requests[msg.sender].fromMember = msg.sender;
        requests[msg.sender].valid =1;

        int found = 0;
        for(uint j=0; j<memRequested.length; j++){
            if(memRequested[j] == msg.sender){
                found = 1;
            }
        }
        if(found == 0){
            memRequested.push(msg.sender);
        }

    }

    function approveRequest (address requestedAddress) public onlyMembers payable{
        uint amount1 = requests[requestedAddress].toAmt;
        uint amount2 = requests[requestedAddress].fromAmt;
        uint index1 =0;
        uint index2 =0;
        uint found1 =0;
        uint found2 =0;
        uint sucess =0;
        uint index=0;

        for(uint i=0; i<memRequested.length; i++){
            if(memRequested[i] == requestedAddress){
                index = i;
            }
        }

        for (uint i=0; i < memberDetails[msg.sender].currencies.length; i++){
            if (keccak256(abi.encodePacked(memberDetails[msg.sender].currencies[i])) == keccak256(abi.encodePacked(requests[msg.sender].currency))){
                index1 = i;
                found1 = 1;
            }
        }

        for (uint i=0; i < memberDetails[requestedAddress].currencies.length; i++){
            if (keccak256(abi.encodePacked(memberDetails[requestedAddress].currencies[i])) == keccak256(abi.encodePacked(requests[requestedAddress].currency))){
                index2 = i;
                found2 = 1;
            }
        }

        if(requests[requestedAddress].valid == 1 ){
            if(requests[requestedAddress].toToken && (found2 == 1 || msg.sender == admin)){
                require(ERC20(token).balanceOf(msg.sender) >= amount1, "Insufficient Token");
                require(ERC20(token).allowance(msg.sender,address(this)) >= amount1, "Insufficient Allowance");
                require(memberDetails[requestedAddress].currencyAmt[index2] >= amount2, "Insufficient Currency");
                ERC20(token).transferFrom(msg.sender,address(this),amount1);
                ERC20(token).transfer(requestedAddress, amount1);
                sucess = 1;
                requests[requestedAddress].valid = 0;
                delete memRequested[index];

                if(found1 == 0){
                    memberDetails[msg.sender].currencies.push(requests[requestedAddress].currency);
                    memberDetails[msg.sender].currencyAmt.push(amount2);
                }else{
                    memberDetails[msg.sender].currencyAmt[index1] += amount2;
                }
                memberDetails[requestedAddress].currencyAmt[index2] -= amount2;
            }
            if(requests[requestedAddress].fromToken == true && (found1 == 1 || msg.sender == admin)){
                require(ERC20(token).balanceOf(requestedAddress) >= amount2, "Insufficient Token");
                require(ERC20(token).allowance(requestedAddress, address(this)) >= amount2, "Insufficient Allowance");

                if(msg.sender != admin){
                    require(memberDetails[msg.sender].currencyAmt[index1] >= amount1, "Insufficient Currency");
                    memberDetails[msg.sender].currencyAmt[index1] -= amount1;
                }
                if(found2 == 0){
                        memberDetails[requestedAddress].currencies.push(requests[requestedAddress].currency);
                        memberDetails[requestedAddress].currencyAmt.push(amount1);
                    }
                    else{
                        memberDetails[requestedAddress].currencyAmt[index2] += amount1;
                }
                ERC20(token).transferFrom(requestedAddress,address(this), amount2);
                ERC20(token).transfer(msg.sender, amount2);
                sucess = 1;
                requests[requestedAddress].valid = 0;
                delete memRequested[index];
            }
        }else{
            revert();
        }
    }

    function getMemRequested() public onlyMembers view returns(address[] memory){
        return memRequested;
    }

    function getDetailByMem(address member) public onlyMembers view returns(string memory, uint256, uint256, address , bool, bool, uint){
        return (requests[member].currency,requests[member].fromAmt,requests[member].toAmt,requests[member].fromMember,requests[member].toToken,requests[member].fromToken,requests[member].valid);
    }

    function getDetail () public onlyMembers view returns(string[] memory, uint256[] memory, uint256[] memory, address[] memory, bool[] memory, bool[] memory, uint[] memory, string memory){
        string[] memory ret1 = new string[](memRequested.length);
        uint256[] memory ret2 = new uint256[](memRequested.length);
        uint256[] memory ret3 = new uint256[](memRequested.length);
        address[] memory ret4 = new address[](memRequested.length);
        bool[] memory ret5 = new bool[](memRequested.length);
        bool[] memory ret6 = new bool[](memRequested.length);
        uint[] memory ret7 = new uint[](memRequested.length);
        for(uint i=0; i<memRequested.length; i++){
          ret1[i] = requests[memRequested[i]].currency;
          ret2[i] = requests[memRequested[i]].fromAmt;
          ret3[i] = requests[memRequested[i]].toAmt;
          ret4[i] = requests[memRequested[i]].fromMember;
          ret5[i] = requests[memRequested[i]].toToken;
          ret6[i] = requests[memRequested[i]].fromToken;
          ret7[i] = requests[memRequested[i]].valid;
        }
        return(ret1, ret2, ret3, ret4, ret5, ret6, ret7, ret1[ret1.length-1]);
    }


    function cancelRequest () public onlyMembers{
        uint index=0;
        for(uint i=0; i<memRequested.length; i++){
            if(memRequested[i] == msg.sender){
                index = i;
            }
        }
        requests[msg.sender].valid = 0;
        delete memRequested[index];
    }

    function getStatus() public view returns(uint, uint){
        return (memberDetails[msg.sender].membership, memberDetails[msg.sender].currencies.length);
    }

    function getCurrency(uint index) public view onlyMembers returns(string memory, uint){
        return (memberDetails[msg.sender].currencies[index], memberDetails[msg.sender].currencyAmt[index]);
    }

    function clean() public onlyAdmin{
        delete memRequested;
    }

}
