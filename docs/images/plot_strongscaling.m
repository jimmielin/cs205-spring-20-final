plot(cores,time_Cannon,'o-','linewidth',2);
hold on;
plot(cores_1n_c54x,time_1n_c54x,'x-','linewidth',2);
plot(cores_2n_c54x,time_2n_c54x,'x--','linewidth',2);

plot(cores_1n_c59x,time_1n_c59x,'v--','linewidth',2);
perfect=zeros(6,2);
perfect(:,1)=[100 200 400 800 1600 3200]
perfect(:,2)=perfect(:,1)./64;
plot([1,64],perfect,'g-.');
set(gca,'yscale','log');
set(gca,'xscale','log');
legend('Cannon','c5.4xlarge 1 node','c5.4xlarge 2 nodes','c5.9xlarge 1 node','fontsize',12);
xlabel('Cores');
ylabel('Runtime (s)')

title('Runtime: Strong Scaling');
set(gca,'fontsize',12,'ytick',10.^(0:0.5:4));
ytickformat('%,.0f')