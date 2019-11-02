pragma solidity >=0.4.22 <0.6.0;
contract fog{
int total;
       int[]total_rep;
       int[]response_time;
       int[]availability;
       int[]capacity;
       address[] rater;
       bool exists;
}
contract client{
           int credibility;
       int ratings;
       bool exists;
       uint bal;
       bool deposit_needed;
       mapping (address => int) last_score;
}
contract reg_client{
    struct client_type{
        int credibility;
        int ratings;
        bool exists;
        uint bal;
        bool deposit_needed;
        mapping (address => int) last_score;
}
mapping(address => client_type) public clients;

function() external payable{
    if(clients[msg.sender].exists){
        clients[msg.sender].bal = msg.value;
        clients[msg.sender].deposit_needed = false;

    }
    else{
        register_client();
    }
}
    function register_client () public payable returns(bool){
        client_type memory temp;
        temp.credibility = 80;
        temp.ratings = 20;
        temp.bal = msg.value;
        temp.exists = true;
        temp.deposit_needed = false;
        clients[msg.sender] = temp;
        }
        function getbal() public view returns (uint){
            return address(this).balance;
        }
}
contract reg_fog{
    struct fog_type{
        int total;
       int[]total_rep;
       int[]response_time;
       int[]availability;
       int[]capacity;
       address[] rater;
       bool exists;
    }
    address owner;
    constructor() public{
        owner = msg.sender;
    }
    modifier onlyOwner(){
        require(
            msg.sender==owner,
            "Sender not authorized."
            );
        _;
    }
    function() external payable{
    register_fog();
}
       mapping (address => fog_type) public fog_nodes;
        function register_fog() public onlyOwner{
        fog_type memory temp;
        temp.exists = true;
        fog_nodes[msg.sender] = temp;
    }
}

contract Reputation is reg_client,reg_fog{
   event ScoreSuccessful(bool status, address ClientAddress, address FogAddress);
   event ReputationScore(int rep_score);
   //event CustomRep(int custom_rep);
   event ClientNode(int credibility, int numofratings);

    function score (int response_time, int availability,int capacity, address fog_node) public {
        //require(clients[msg.sender].exists && fog_nodes[fog_node].exists && fog_node!=msg.sender);
        //require(response_time>0 && response_time<=100 && availability>0 && availability<=100 && capacity>=0 && capacity<=100);
        fog_nodes[fog_node].response_time.push(response_time);
        fog_nodes[fog_node].availability.push(availability);
        fog_nodes[fog_node].capacity.push(capacity);
        fog_nodes[fog_node].total_rep.push((response_time+availability+capacity)/3);
        fog_nodes[fog_node].rater.push(msg.sender);
        clients[msg.sender].ratings++;
//        emit ScoreSuccessful(true,fog_node,msg.sender);
    }
    function calculateRep (address fog_node) public {
        int repp = 0;
        int total_crr = 0;
        for (uint i = 0;i<fog_nodes[fog_node].total_rep.length;i++){
            repp += clients[fog_nodes[fog_node].rater[i]].credibility*fog_nodes[fog_node].total_rep[i];
            total_crr += clients[fog_nodes[fog_node].rater[i]].credibility;
        }
        repp /= total_crr;
        fog_nodes[fog_node].total = repp;
        //emit ReputationScore(repp);
    }
       function get(address fog_node) view public returns (uint){
       return fog_nodes[fog_node].response_time.length;
   }
}

contract Credibility is reg_client, reg_fog{
    int majority_rep;
   int consistency_threshold;
   int trustworthiness_threshold;
   int ratings_threshold;
   int credibility_threshold;
          int tolerance_thresold;


   struct head{
       int value;
       int votes;
       int center;
       int cr;
   }
   head[] public heads;
   constructor() public{
        consistency_threshold = 90;
        trustworthiness_threshold = 90;
        ratings_threshold = 2;
        credibility_threshold = 85;
        tolerance_thresold = 5;
    }
    function get(address fog_node) view public returns (uint){
       return fog_nodes[fog_node].response_time.length;
   }
    function calculateReputation (address fog_node) public {
        head memory t;
        delete heads;
        t.votes = 1;
        t.value = fog_nodes[fog_node].total_rep[0];
        t.center = t.value;
        t.cr = clients[fog_nodes[fog_node].rater[0]].credibility;
        heads.push(t);
        for(uint i = 1;i<fog_nodes[fog_node].total_rep.length;i++){
            int min = 100;
            uint min_index;
                    for(uint j = 0;j<heads.length;j++){
                        int temp = heads[j].value-fog_nodes[fog_node].total_rep[i];
                        if(temp<=tolerance_thresold && temp<min && temp>=0){
                            min = temp;
                            min_index = j;
                        }
                        else {
                            temp *= -1;
                            if(temp<=tolerance_thresold && temp<min && temp>=0){
                                min = temp;
                                min_index = j;
                            }
                        }
                    }
                    if(min!=100){
                        heads[min_index].votes++;
                        heads[min_index].cr += clients[fog_nodes[fog_node].rater[i]].credibility;
                        heads[min_index].center += fog_nodes[fog_node].total_rep[i];
                    }
                    else{
                        t.votes = 1;
                        t.value = fog_nodes[fog_node].total_rep[i];
                        t.center = t.value;
                        t.cr = clients[fog_nodes[fog_node].rater[i]].credibility;
                        heads.push(t);
                    }
        }
        int max = 0;
        int max_rep = 0;
        for(uint j = 0;j<heads.length;j++){
                     if(heads[j].cr>=max){
                         max = heads[j].cr;
                         max_rep = heads[j].center/heads[j].votes;
                     }
        }
        //calculateRep(fog_node);
        majority_rep = max_rep;
    }
        function calculateCredibility (address fog_node) public {
        //emit ClientNode(clients[msg.sender].credibility,clients[msg.sender].ratings);
        int current_reputation = fog_nodes[fog_node].total_rep[fog_nodes[fog_node].total_rep.length-1];
        int cr;
        int consistency = 0;
        int trustworthiness = 0;
        //majority_rep = calculateReputation(fog_node);
        int adjusting_factor = 4;
        trustworthiness = majority_rep - current_reputation;
        if(trustworthiness<0){
            trustworthiness *= -1;
        }
        trustworthiness = 100 - trustworthiness;
        if(clients[msg.sender].last_score[fog_node]!=0){
            consistency = clients[msg.sender].last_score[fog_node] - current_reputation;
            if(consistency<0){
                consistency *= -1;
            }
            consistency = 100 - consistency;
        }
        clients[msg.sender].last_score[fog_node] = current_reputation;
        if(consistency>consistency_threshold && trustworthiness>trustworthiness_threshold){
            cr = (clients[msg.sender].credibility*(consistency+trustworthiness))/(4*adjusting_factor);
            if(clients[msg.sender].ratings<ratings_threshold){
                cr = cr*clients[msg.sender].ratings/ratings_threshold;
            }
            cr /= 100;
            clients[msg.sender].credibility += cr;
        }
        else if(trustworthiness>trustworthiness_threshold){
            cr = (clients[msg.sender].credibility*trustworthiness)/(4*adjusting_factor);
            if(clients[msg.sender].ratings<ratings_threshold){
                cr = cr*clients[msg.sender].ratings/ratings_threshold;
            }
            cr /= 100;
            clients[msg.sender].credibility += cr;
        }
        else if(consistency>consistency_threshold){
            cr = (clients[msg.sender].credibility*consistency)/(4*(10-adjusting_factor));
            if(clients[msg.sender].ratings<ratings_threshold){
                cr = cr*clients[msg.sender].ratings/ratings_threshold;
            }
            cr /= 100;
            clients[msg.sender].credibility -= cr;
        }
        else{
            cr = (clients[msg.sender].credibility*(consistency+trustworthiness))/(4*(10-adjusting_factor));
            if(clients[msg.sender].ratings<ratings_threshold){
                cr = cr*clients[msg.sender].ratings/ratings_threshold;
            }
            cr /= 100;
            clients[msg.sender].credibility -= cr;
        }
        if (clients[msg.sender].credibility<0){
            clients[msg.sender].credibility = 0;
        }
        else if (clients[msg.sender].credibility>100){
            clients[msg.sender].credibility = 100;
        }
    }
    function manageDeposit () public {
        if(clients[msg.sender].credibility>=credibility_threshold && clients[msg.sender].bal!=0)
        {
            address(msg.sender).transfer(clients[msg.sender].bal*1 ether);
            clients[msg.sender].bal = 0;

        }
        if(clients[msg.sender].credibility<credibility_threshold && clients[msg.sender].bal==0){
            clients[msg.sender].deposit_needed = true;
        }

}
}

contract Custom_Reputation is reg_fog, reg_client{

        function customizableRep(int a_pref, int b_pref, int c_pref, address fog_node) public view returns (int){
        int rep = 0;
        int total_cr = 0;
        for (uint i = 0;i<fog_nodes[fog_node].response_time.length;i++){
            rep += fog_nodes[fog_node].response_time[i]*a_pref+fog_nodes[fog_node].availability[i]*b_pref+fog_nodes[fog_node].capacity[i]*c_pref;
            rep *= clients[fog_nodes[fog_node].rater[i]].credibility;
            rep /= a_pref+b_pref+c_pref;
            total_cr += clients[fog_nodes[fog_node].rater[i]].credibility;
        }
        rep /= total_cr;
        return rep;
    }
}

/*contract main{
    address payable add =0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c;

    client cl;
    fog fo;
    reg_client c;
    reg_fog f;
    Reputation r;
    Credibility cr;
    Custom_Reputation cs;
    constructor()public{
        cl=client(add);
        fo=fog(add);
        c=reg_client(add);
        f=reg_fog(add);
        r=Reputation(add);
        cr=Credibility(add);
        cs= Custom_Reputation(add);
        c.register_client();
    }

}*/
