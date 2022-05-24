// this model includes 1 client, 1 primary node and 3 backup nodes

ctmc

const rate_client=1000;
const rate_primary=1000;
const rate_backup=1000;

const rate_digest=27800;
const rate_commit=27800;

const bool f; // failure nodes, threshold 2f+1=5, service node 3f+1=7

global reply : bool;// signal for the end

module PBFT
	phase : [1..5]; // 1 for "request", 2 for "pre-prepare"...
	digested_1 : bool;
	digested_2 : bool;
	digested_3 : bool;
	commited_0 : bool;
	commited_1 : bool;
	commited_2 : bool;
	commited_3 : bool;

	[request] phase=1 -> rate_client:(phase'=2);
	[pre_prepare] phase=2 -> rate_primary:(phase'=3);

	[compute_digest_1] phase=3 & digested_1=false -> rate_digest:(digested_1'=true);
	[compute_digest_2] phase=3 & digested_2=false -> rate_digest:(digested_2'=true);
	[compute_digest_3] phase=3 & digested_3=false -> rate_digest:(digested_3'=true);

	[prepare_1] phase=3 & digested_1 -> rate_backup:(digested_1'=true);
	[prepare_2] phase=3 & digested_2 -> rate_backup:(digested_2'=true);
	[prepare_3] phase=3 & digested_3 -> rate_backup:(digested_3'=true);

	[compute_commit_0] commited_1=false -> rate_commit:(commited_0'=true);
	[compute_commit_1] commited_1=false -> rate_commit:(commited_1'=true);
	[compute_commit_2] commited_1=false -> rate_commit:(commited_2'=true);
	[compute_commit_3] commited_1=false -> rate_commit:(commited_3'=true);

	[commit_0] commited_0=true -> rate_primary:(commited_0'=true);
	[commit_1] commited_1=true -> rate_primary:(commited_1'=true);
	[commit_2] commited_2=true -> rate_primary:(commited_2'=true);
	[commit_3] commited_3=true -> rate_primary:(commited_3'=true);
endmodule

module backup_1
	receive_request_1 : bool;
	send_digest_1_to_0 : bool;
	send_digest_1_to_2 : bool;
	send_digest_1_to_3 : bool;
	send_commit_1_to_0 : bool;
	send_commit_1_to_2 : bool;
	send_commit_1_to_3 : bool;

	commits_1 : [0..6];
	digests_1 : [0..6];
	
	[pre_prepare] receive_request_1 = false -> (receive_request_1' = true);

	[compute_digest_1] receive_request_1 & digests_1=0-> (digests_1'=digests_1+1);  

	[prepare_1] !send_digest_1_to_0 -> (send_digest_1_to_0'=true);
	[prepare_1] !send_digest_1_to_2 -> (send_digest_1_to_2'=true);
	[prepare_1] !send_digest_1_to_3 -> (send_digest_1_to_3'=true);

	[prepare_2] true -> (digests_1'=digests_1+1);
	[prepare_3] true -> (digests_1'=digests_1+1);

	[compute_commit_1] digests_1 >=2 & commits_1=0 -> (commits_1' = commits_1+1);

	[commit_1] !send_commit_1_to_0 -> (send_commit_1_to_0'=true);
	[commit_1] !send_commit_1_to_2 -> (send_commit_1_to_2'=true);
	[commit_1] !send_commit_1_to_3 -> (send_commit_1_to_3'=true);
	
	[commit_0] true -> (commits_1'=commits_1+1);
	[commit_2] true -> (commits_1'=commits_1+1);
	[commit_3] true -> (commits_1'=commits_1+1);
	
	[] commits_1>=3 -> rate_backup:(reply'=true);
endmodule

module backup_2=backup_1[compute_commit_1=compute_commit_2,compute_digest_1=compute_digest_2,prepare_1=prepare_2,prepare_2=prepare_1,commit_1=commit_2,commit_2=commit_1,commits_1=commits_2,digests_1=digests_2,receive_request_1=receive_request_2,send_digest_1_to_0=send_digest_2_to_0,send_digest_1_to_2=send_digest_2_to_1,send_digest_1_to_3=send_digest_2_to_3,send_commit_1_to_0=send_commit_2_to_0,send_commit_1_to_2=send_commit_2_to_1,send_commit_1_to_3=send_commit_2_to_3] endmodule
module backup_3=backup_1[compute_commit_1=compute_commit_3,compute_digest_1=compute_digest_3,prepare_1=prepare_3,prepare_3=prepare_1,commit_1=commit_3,commit_3=commit_1,commits_1=commits_3,digests_1=digests_3,receive_request_1=receive_request_3,send_digest_1_to_0=send_digest_3_to_0,send_digest_1_to_2=send_digest_3_to_2,send_digest_1_to_3=send_digest_3_to_1,send_commit_1_to_0=send_commit_3_to_0,send_commit_1_to_2=send_commit_3_to_2,send_commit_1_to_3=send_commit_3_to_1] endmodule

module primary
	digests_0 : [0..6];
	commits_0 : [0..6];
	receive_request_0 : bool;
	send_commit_0_to_1 : bool;
	send_commit_0_to_2 : bool;
	send_commit_0_to_3 : bool;
	[request] receive_request_0=false -> (receive_request_0' = true);

	[prepare_1] true -> (digests_0'=digests_0+1);
	[prepare_2] true -> (digests_0'=digests_0+1);
	[prepare_3] true -> (digests_0'=digests_0+1);

	[compute_commit_0] digests_0 >=2 & digests_0=0-> (commits_0' = commits_0+1);

	[commit_0] !send_commit_0_to_1 -> (send_commit_0_to_1'=true);
	[commit_0] !send_commit_0_to_2 -> (send_commit_0_to_2'=true);
	[commit_0] !send_commit_0_to_3 -> (send_commit_0_to_3'=true);
	
	[commit_1] true -> (commits_0'=commits_0+1);
	[commit_2] true -> (commits_0'=commits_0+1);
	[commit_3] true -> (commits_0'=commits_0+1);
	
	[] commits_0>=3 -> rate_backup:(reply'=true);
endmodule


label "finish" = reply=true;

