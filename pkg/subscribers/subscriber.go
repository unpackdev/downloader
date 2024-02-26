package subscribers

type Subscriber interface {
	Start() error
	Stop() error
	Status() Status
}
