# Example of process


Few examples of plan uml process


## plan uml example  1

```plantuml
Bob -> Alice : hello
Alice -> Bob : Go Away
```

## plan uml example  2

```plantuml  format="svg"
autonumber "<b>[000]"
Bob -> Alice : Authentication Request
Bob <- Alice : Authentication Response

autonumber 15 "<b>(<u>##</u>)"
Bob -> Alice : Another authentication Request
Bob <- Alice : Another authentication Response

autonumber 40 10 "<font color=red><b>Message 0  "
Bob -> Alice : Yet another authentication Request
Bob <- Alice : Yet another authentication Response

```


## plan uml example 3

```plantuml
start
:Init Phase;
:Transfer Phase;
note right
  long running activity,
  process requires signal to proceed
end note
:Termination Phase;
stop
```


## PlantUML diagram with AWS architecture

```plantuml
@startuml architecture_aws_01 format="png"
!define AWSPuml https://raw.githubusercontent.com/awslabs/aws-icons-for-plantuml/master/dist
!includeurl AWSPuml/AWSCommon.puml
!includeurl AWSPuml/NetworkingAndContentDelivery/VPC.puml
!includeurl AWSPuml/Compute/Compute.puml
!includeurl AWSPuml/NetworkingAndContentDelivery/VPCInternetGateway.puml
!includeurl AWSPuml/Compute/ElasticKubernetesService.puml
!includeurl AWSPuml/Compute/ECSContainer2.puml
!includeurl AWSPuml/NetworkingAndContentDelivery/ElasticLoadBalancing.puml

'LAYOUT_TOP_DOWN
'LAYOUT_LEFT_RIGHT


VPC(aws_vpc, "My Company VPC" , "AWS VPC")  {

    ElasticLoadBalancing(elb, "Load balancer", "AWS ELB")

    ElasticKubernetesService(eks,"Kubernetes Cluster", "AWS EKS") {

        rectangle "Zone A" { 
            ECSContainer2(za_cont_1,"Web server container", "Docker container") {
                component "Flask API server" as za_prom_ret
            }
     
            Compute(za_vm_ec2, "Virtual Machine", "EC2") {
                 component "Legacy app" as za_prom_tsdb1
            }
            za_prom_ret -down-> za_prom_tsdb1
        }

        rectangle "Zone B" { 
            ECSContainer2(zb_cont_1,"Web server container", "Docker container") {
                component "Flask API server" as zb_prom_ret
            }        
            Compute(vm_ec2, "Virtual Machine", "EC2") {
                 component "Legacy app" as zb_prom_tsdb1
            }
            zb_prom_ret -down-> zb_prom_tsdb1
        }
        za_prom_tsdb1 <-left-> zb_prom_tsdb1: "  sync  "
    }
    elb -down-> za_prom_ret: http
    elb -down-> zb_prom_ret: http
}

@enduml
```





## plan uml example  4


::uml:: format="png" classes="uml myDiagram" alt="My super diagram placeholder" title="My super diagram" width="300px" height="300px"
  Goofy ->  MickeyMouse: calls
  Goofy <-- MickeyMouse: responds
::end-uml::

## image png

Below an example of png image

![process](images/test-process.png)


## image svg

Below an example of svg image

![process](images/test-diagramm-1.svg)



## Equation

The Cauchy-Schwarz Inequality:

\begin{equation*}
\left( \sum_{k=1}^n a_k b_k \right)^2 \leq \left( \sum_{k=1}^n a_k^2 \right) \left( \sum_{k=1}^n b_k^2 \right)
\end{equation*}

### Mathjax 

Example:

$$x = {-b \pm \sqrt{b^2-4ac} \over 2a}.$$


end of document


